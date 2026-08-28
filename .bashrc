# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# /etc/omarchy.conf is written by omarchy-dev-link. When absent, force the
# package default instead of preserving a stale inherited dev-link value before
# we decide which rc file to source.
if [[ -f /etc/omarchy.conf ]]; then
  source /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
else
  export OMARCHY_PATH=/usr/share/omarchy
fi
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.

bind -f ~/.inputrc

alias ll='ls -alh'
alias sll='sudo ls -alh'
alias vult='ssh -i {{SSH_KEY}} {{SSH_USER}}@{{SSH_HOST}}'
alias dc='cd'
alias ref1='sudo reflector --country "United States" --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist'
alias ref2='sudo pacman -Syy'
alias steam='SDL_GAMECONTROLLERCONFIG="" steam &'
alias swapoff="sed -i 's/^\(\s*\)-- kb_options = /\1kb_options = /' ~/.config/hypr/input.lua && hyprctl reload"
alias swapon="sed -i 's/^\(\s*\)kb_options = /\1-- kb_options = /' ~/.config/hypr/input.lua && hyprctl reload"
alias p='uv run'

# Local Dev Docker (uses docker-compose.override.yaml)
alias dbuild='docker compose build'
alias dup='docker compose up -d'
alias ddown='docker compose down'
alias dlogs='docker compose logs api'
alias dlogsf='docker compose logs -f api'
alias dps='docker compose ps'

# Paths
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/.cargo/bin


# Functions
_vpn_noise='EventletDeprecationWarning|Eventlet is deprecated|recommend against using it|already using Eventlet|For more detail see|eventlet\.readthedocs\.io|is_monkey_patched|^[[:space:]]*$'
vpn() {
  case "$1" in
    up)
      protonvpn connect --country "${2^^}" 2> >(grep -Ev "$_vpn_noise" >&2)
      ;;
    down)
      protonvpn disconnect 2> >(grep -Ev "$_vpn_noise" >&2)
      ;;
    help|"")
      cat <<EOF
Usage:
  vpn up <country-code>   Connect to a country (e.g. vpn up us)
  vpn down                Disconnect
  vpn help                Show this help
  protonvpn countries list   List all available country codes
EOF
      ;;
    *)
      echo "Unknown command: $1" >&2
      vpn help
      return 1
      ;;
  esac
}
