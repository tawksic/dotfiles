# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.

bind -f ~/.inputrc

alias ll='ls -alh'
alias vult='ssh -i ~/.ssh/ov tyler@CHANGEME'
alias dc='cd'
alias ref1='sudo reflector --country "United States" --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist'
alias ref2='sudo pacman -Syy'

# Local Dev Docker (uses docker-compose.override.yaml)
alias dbuild='docker compose build'
alias dup='docker compose up -d'
alias ddown='docker compose down'
alias dlogs='docker compose logs api'          # ← Changed: webapp → api
alias dlogsf='docker compose logs -f api'      # ← Changed: webapp → api
alias dps='docker compose ps'

