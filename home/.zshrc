# --- HIST FILE ---
HISTFILE="$HOME/.histfile"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# --- BINDKEYS ---
bindkey -e
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^H" backward-kill-word
bindkey "^[[127;5u" backward-kill-word
bindkey "^[[3;5~" kill-word

# --- COMPINIT WITH CACHE ---
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit

if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m+1) ]]; then
	compinit
else
	compinit -C
fi

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# --- Aliases ---
alias l='lsd --group-dirs first'
alias ls='lsd --group-dirs first'
alias ll='lsd -lh --group-dirs first'
alias lr='lsd -R --group-dirs first'
alias llr='lsd -lhR --group-dirs first'
alias la='lsd -a --group-dirs first'
alias lla='lsd -la --group-dirs first'
alias cat='bat'

# --- STYLES ---
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=242"
export FZF_DEFAULT_OPTS='
  --color=fg:#E0E6ED,bg:#0A0C0E,hl:#00FF66
  --color=fg+:#E0E6ED,bg+:#121518,hl+:#00FF66
  --color=info:#00B347,prompt:#00FF66,pointer:#00FF66,marker:#00FF66,spinner:#00FF66,header:#00B347
  --prompt="❯ " --pointer="▶"
'

function man() {
	env \
		LESS_TERMCAP_mb=$'\e[01;31m' \
		LESS_TERMCAP_md=$'\e[01;32m' \
		LESS_TERMCAP_me=$'\e[0m' \
		LESS_TERMCAP_se=$'\e[0m' \
		LESS_TERMCAP_so=$'\e[01;30;42m' \
		LESS_TERMCAP_ue=$'\e[0m' \
		LESS_TERMCAP_us=$'\e[01;36m' \
		man "$@"
}

# --- Functions ---
function rmk() {
	shred -zun 10 -v $1
}

function fzf-lovely() {
	if [ "$1" = "h" ]; then
		fzf -m --reverse --preview-window down:20 --preview '[[ $(file --mime {}) =~ binary ]] &&
                    echo {} is a binary file ||
                     (bat --style=numbers --color=always {} ||
                      highlight -O ansi -l {} ||
                      coderay {} ||
                      rougify {} ||
                      cat {}) 2> /dev/null | head -500'
	else
		fzf -m --preview '[[ $(file --mime {}) =~ binary ]] &&
                             echo {} is a binary file ||
                             (bat --style=numbers --color=always {} ||
                              highlight -O ansi -l {} ||
                              coderay {} ||
                              rougify {} ||
                              cat {}) 2> /dev/null | head -500'
	fi
}

function clear-history() {
	echo "" >$HOME/.bash_history
	echo "" >$HOME/.histfile
	exit 0
}

# --- Plugins ---
source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.zsh/zsh-sudo/sudo.plugin.zsh"
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# --- PATH ---
export PATH="$PATH:/opt/jetbrains-toolbox-2.2.3.20090:$HOME/.flutter/bin:$HOME/.spicetify"

# --- STARSHIP ---
eval "$(starship init zsh)"
