#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys
import textwrap

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib

DBUS_NAME = "org.freedesktop.Notifications"
DBUS_PATH = "/org/freedesktop/Notifications"


class NotificationServer(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, DBUS_PATH)
        self.current_id = 1
        self.toasts = {}
        self.history = []
        self.unread_count = 0
        self.is_window_open = False

    def _get_next_id(self):
        return self.current_id

    def _wrap_text(self, text, width):
        lines = []
        for paragraph in text.split("\n"):
            if paragraph.strip():
                lines.append(textwrap.fill(paragraph, width=width))
            else:
                lines.append("")

        return "\n".join(lines)

    def _clean_text(self, text):
        if not text:
            return ""
        clean = re.sub(r"<br\s*/?>", "\n", str(text), flags=re.IGNORECASE)
        clean = re.sub(r"</p>", "\n", clean, flags=re.IGNORECASE)
        clean = re.sub(r"<[^>]*>", "", clean)
        return clean.strip()

    @dbus.service.method(DBUS_NAME, in_signature="susssasa{sv}i", out_signature="u")
    def Notify(
        self,
        app_name,
        replaces_id,
        app_icon,
        summary,
        body,
        actions,
        hints,
        timeout,
    ):
        notif_id = replaces_id if replaces_id != 0 else self._get_next_id()

        urgency_val = int(hints.get("urgency", 1))
        urgency_map = {0: "low", 1: "normal", 2: "critical"}
        urgency_str = urgency_map.get(urgency_val, "normal")

        if replaces_id == 0:
            self.current_id += 1

        if notif_id in self.toasts:
            existing_timer = self.toasts[notif_id].get("timer_id")
            if existing_timer is not None:
                try:
                    GLib.source_remove(existing_timer)
                except Exception:  # noqa: BLE001, S110
                    pass

        self._play_sound()
        icon = self._resolve_icon(str(app_name), str(app_icon))

        action_list = list(actions)
        default_action = action_list[0] if len(action_list) >= 2 else None

        timer_id = None
        if urgency_str != "critical":
            timer_id = GLib.timeout_add(5000, self._auto_dismiss, notif_id)

        is_new = notif_id not in self.toasts

        clean_app = self._clean_text(app_name) or "Sistema"
        clean_summary = self._clean_text(summary)
        clean_body = self._clean_text(body)

        summary_line = " ".join(clean_summary.split())
        body_line = " ".join(clean_body.split())

        # Evaluar si la notificación contiene más texto del que entra por defecto
        has_more = (
            len(summary_line) > 38
            or len(body_line) > 44
            or "\n" in clean_summary
            or "\n" in clean_body
        )

        data = {
            "id": notif_id,
            "app": clean_app,
            "summary": clean_summary,
            "body": clean_body,
            "icon": icon,
            "urgency": urgency_str,
            "has_action": default_action is not None,
            "default_action": default_action if default_action else "",
            "timer_id": timer_id,
            "reveal": not is_new,
            "closing": False,
        }

        self.toasts[notif_id] = data

        hist_data = {
            k: v for k, v in data.items() if k not in ("timer_id", "reveal", "closing")
        }
        hist_data["summary_line"] = summary_line
        hist_data["body_line"] = body_line
        hist_data["summary_wrapped"] = self._wrap_text(clean_summary, 38)
        hist_data["body_wrapped"] = self._wrap_text(clean_body, 42)
        hist_data["has_more"] = has_more

        # Reemplazar en vez de duplicar, conservando el estado expandido
        prev = next((h for h in self.history if h["id"] == notif_id), None)
        hist_data["expanded"] = prev["expanded"] if (prev and has_more) else False
        self.history = [h for h in self.history if h["id"] != notif_id]
        self.history.insert(0, hist_data)

        self.unread_count += 1
        self._update_eww()

        if is_new:
            GLib.timeout_add(50, self._animate_in, notif_id)

        return dbus.UInt32(notif_id)

    def _animate_in(self, notif_id):
        if notif_id in self.toasts and not self.toasts[notif_id].get("closing", False):
            self.toasts[notif_id]["reveal"] = True
            self._update_eww()
        return False

    @dbus.service.method(DBUS_NAME, in_signature="u", out_signature="")
    def CloseNotification(self, notif_id):
        notif_id = int(notif_id)
        if notif_id in self.toasts and not self.toasts[notif_id].get("closing", False):
            self.toasts[notif_id]["closing"] = True
            self.toasts[notif_id]["reveal"] = False

            timer_id = self.toasts[notif_id].get("timer_id")
            if timer_id is not None:
                try:
                    GLib.source_remove(timer_id)
                except Exception:  # noqa: BLE001, S110
                    pass

            self._update_eww()
            GLib.timeout_add(380, self._finish_close, notif_id)

    def _finish_close(self, notif_id):
        if notif_id in self.toasts:
            del self.toasts[notif_id]
            self._update_eww()
            try:
                self.NotificationClosed(dbus.UInt32(notif_id), dbus.UInt32(2))
            except Exception:  # noqa: BLE001, S110
                pass
        return False

    @dbus.service.method(DBUS_NAME, in_signature="u", out_signature="")
    def TriggerAction(self, notif_id):
        notif_id = int(notif_id)
        if notif_id in self.toasts:
            notif = self.toasts[notif_id]

            if notif.get("has_action"):
                try:
                    self.ActionInvoked(
                        dbus.UInt32(notif_id), str(notif["default_action"])
                    )
                except Exception:  # noqa: BLE001, S110
                    pass

            try:
                self._launch_app(notif["app"])
            except Exception:  # noqa: BLE001, S110
                pass

            self.CloseNotification(notif_id)

    @dbus.service.method(DBUS_NAME, in_signature="u", out_signature="")
    def DeleteHistory(self, notif_id):
        notif_id = int(notif_id)
        self.history = [h for h in self.history if h.get("id") != notif_id]
        self._update_eww()

    @dbus.service.method(DBUS_NAME, in_signature="u", out_signature="")
    def ToggleExpandHistory(self, notif_id):
        notif_id = int(notif_id)
        for h in self.history:
            if h.get("id") == notif_id and h.get("has_more", False):
                h["expanded"] = not h.get("expanded", False)
                break
        self._update_eww()

    @dbus.service.method(DBUS_NAME, in_signature="", out_signature="")
    def ClearHistory(self):
        self.history = []
        self.unread_count = 0
        self._update_eww()

    @dbus.service.method(DBUS_NAME, in_signature="", out_signature="")
    def ResetCount(self):
        self.unread_count = 0
        self._update_eww()

    @dbus.service.method(DBUS_NAME, in_signature="", out_signature="as")
    def GetCapabilities(self):
        return ["body", "actions", "icon-static"]

    @dbus.service.method(DBUS_NAME, in_signature="", out_signature="ssss")
    def GetServerInformation(self):
        return ("Eww Notification Daemon", "Custom", "1.0", "1.2")

    @dbus.service.signal(DBUS_NAME, signature="uu")
    def NotificationClosed(self, id, reason):
        pass

    @dbus.service.signal(DBUS_NAME, signature="us")
    def ActionInvoked(self, id, action_key):
        pass

    def _launch_app(self, app_name):
        target = app_name.lower()
        cmd = None

        if "firefox" in target:
            cmd = ["firefox"]
        elif "brave" in target:
            cmd = ["brave"]
        elif "discord" in target:
            cmd = ["discord"]
        elif "telegram" in target:
            cmd = ["telegram-desktop"]
        elif "kitty" in target or "terminal" in target:
            cmd = ["kitty"]
        elif "spotify" in target:
            cmd = ["spotify"]

        if cmd:
            try:
                subprocess.Popen(
                    cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
            except Exception as e:  # noqa: BLE001
                print(f"Error al abrir la aplicación {app_name}: {e}")

    def _auto_dismiss(self, notif_id):
        self.CloseNotification(notif_id)
        return False

    def _play_sound(self):
        sound_path = "/usr/share/sounds/freedesktop/stereo/message.oga"
        if os.path.exists(sound_path):
            subprocess.Popen(["paplay", sound_path], stderr=subprocess.DEVNULL)

    def _resolve_icon(self, app_name, app_icon):
        if app_icon and (app_icon.startswith(("/", "file://"))):
            return {"type": "image", "value": app_icon.replace("file://", "")}

        target = f"{app_name} {app_icon}".lower()

        if "battery-low" in target or "battery-caution" in target:
            return {"type": "text", "value": "󰂃"}
        if "battery-full" in target or "battery-charging" in target:
            return {"type": "text", "value": "󰂄"}
        if "battery" in target:
            return {"type": "text", "value": "󰁹"}

        if "firefox" in target:
            return {"type": "text", "value": "󰈹"}
        if "brave" in target:
            return {"type": "text", "value": "󰖟"}
        if "discord" in target:
            return {"type": "text", "value": "󰙯"}
        if "telegram" in target:
            return {"type": "text", "value": "󰔁"}
        if "kitty" in target or "terminal" in target:
            return {"type": "text", "value": "󰞷"}
        if "spotify" in target:
            return {"type": "text", "value": "󰓇"}

        return {"type": "text", "value": "󰂚"}

    def _update_eww(self):
        toasts_json = json.dumps(list(self.toasts.values()))
        history_json = json.dumps(self.history[:20])

        subprocess.run(  # noqa: PLW1510
            [
                "eww",
                "update",
                f"notif_toasts={toasts_json}",
                f"notif_history={history_json}",
                f"notif_count={self.unread_count}",
            ],
            stderr=subprocess.DEVNULL,
        )

        if self.toasts and not self.is_window_open:
            subprocess.run(  # noqa: PLW1510
                ["eww", "open", "notif-toast-window"], stderr=subprocess.DEVNULL
            )
            self.is_window_open = True
        elif not self.toasts and self.is_window_open:
            subprocess.run(  # noqa: PLW1510
                ["eww", "close", "notif-toast-window"],
                stderr=subprocess.DEVNULL,
            )
            self.is_window_open = False


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    session_bus = dbus.SessionBus()

    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        try:
            obj = session_bus.get_object(DBUS_NAME, DBUS_PATH)
            if cmd == "dismiss" and len(sys.argv) > 2:
                obj.CloseNotification(int(sys.argv[2]), dbus_interface=DBUS_NAME)
            elif cmd == "action" and len(sys.argv) > 2:
                obj.TriggerAction(int(sys.argv[2]), dbus_interface=DBUS_NAME)
            elif cmd == "delete_history" and len(sys.argv) > 2:
                obj.DeleteHistory(int(sys.argv[2]), dbus_interface=DBUS_NAME)
            elif cmd == "toggle_expand" and len(sys.argv) > 2:
                obj.ToggleExpandHistory(int(sys.argv[2]), dbus_interface=DBUS_NAME)
            elif cmd == "clear":
                obj.ClearHistory(dbus_interface=DBUS_NAME)
            elif cmd == "reset_count":
                obj.ResetCount(dbus_interface=DBUS_NAME)

        except Exception as e:  # noqa: BLE001
            print(f"Error enviando comando al demonio: {e}")

        return

    name = dbus.service.BusName(DBUS_NAME, session_bus)  # noqa: F841
    server = NotificationServer(session_bus)  # noqa: F841
    loop = GLib.MainLoop()

    loop.run()


if __name__ == "__main__":
    main()
