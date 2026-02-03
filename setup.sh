#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

# ─── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}::${NC} $1"; }
ok()    { echo -e "${GREEN}::${NC} $1"; }
warn()  { echo -e "${YELLOW}::${NC} $1"; }
err()   { echo -e "${RED}::${NC} $1"; }

# ─── Pre-flight checks ───────────────────────────────────────────────────────

if [[ ! -d "$HOME/.local/share/omarchy" ]]; then
    err "Omarchy is not installed. Install it first: https://omarchy.com"
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    err "This script is designed for Arch Linux."
    exit 1
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Omarchy Dotfiles Setup${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""

# ─── Prompts (all upfront) ───────────────────────────────────────────────────

info "SSH configuration (for the 'vult' alias)"
read -rp "  SSH key path [~/.ssh/id_ed25519]: " ssh_key
ssh_key="${ssh_key:-~/.ssh/id_ed25519}"
read -rp "  SSH username: " ssh_user
read -rp "  SSH server IP/hostname: " ssh_host
echo ""

info "WireGuard VPN profiles"
read -rp "  Canada VPN profile name [ppc-ca-van]: " vpn_ca
vpn_ca="${vpn_ca:-ppc-ca-van}"
read -rp "  US VPN profile name [ppc-us-ca]: " vpn_us
vpn_us="${vpn_us:-ppc-us-ca}"
echo ""

info "Keyboard layout"
echo "  1) Mac-style (swap Alt and Ctrl)"
echo "  2) Standard PC (no swap)"
read -rp "  Choice [1]: " kb_choice
kb_choice="${kb_choice:-1}"
if [[ "$kb_choice" == "1" ]]; then
    kb_options="ctrl:swap_lalt_lctl,ctrl:swap_ralt_rctl"
else
    kb_options=""
fi
echo ""

info "NVIDIA GPU"
read -rp "  Install NVIDIA packages? (y/n) [n]: " do_nvidia
do_nvidia="${do_nvidia:-n}"
echo ""

# ─── Monitor detection ───────────────────────────────────────────────────────

info "Detecting monitors..."
workspace_assignments=""
mako_output=""

if command -v hyprctl &>/dev/null; then
    mapfile -t monitors < <(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null || true)
    monitor_count=${#monitors[@]}

    if [[ $monitor_count -eq 0 ]]; then
        warn "No monitors detected. Skipping workspace assignments."
    elif [[ $monitor_count -eq 1 ]]; then
        info "Single monitor detected: ${monitors[0]}"
        info "Skipping workspace-to-monitor assignments."
    else
        info "Monitors found:"
        for i in "${!monitors[@]}"; do
            echo "  $((i+1))) ${monitors[$i]}"
        done
        echo ""

        read -rp "  How many workspaces? [5]: " ws_count
        ws_count="${ws_count:-5}"

        for ((ws=1; ws<=ws_count; ws++)); do
            read -rp "  Workspace $ws -> monitor # [1]: " mon_num
            mon_num="${mon_num:-1}"
            mon_name="${monitors[$((mon_num-1))]}"
            workspace_assignments+="workspace = ${ws}, monitor:${mon_name}"$'\n'
        done

        echo ""
        info "Which monitor should show notifications?"
        for i in "${!monitors[@]}"; do
            echo "  $((i+1))) ${monitors[$i]}"
        done
        read -rp "  Monitor # [1]: " mako_mon
        mako_mon="${mako_mon:-1}"
        mako_output="${monitors[$((mako_mon-1))]}"
    fi
else
    warn "hyprctl not found. Skipping monitor detection."
fi
echo ""

# ─── All prompts done ────────────────────────────────────────────────────────

echo -e "${BOLD}All questions answered. Installing...${NC}"
echo ""

# ─── Package installation ────────────────────────────────────────────────────

info "Installing pacman packages..."

pacman_packages=(
    wget
    bind
    uv
    go
    cursor-bin
    paru
    reflector
    protonup-qt
    libreoffice-fresh
    ttf-liberation
    ttf-dejavu
    noto-fonts
    p7zip
    icoutils
    openvpn
    dialog
    python-pip
    python-setuptools
    wireguard-tools
    openresolv
    flatpak
    proton-vpn-gtk-app
    proton-vpn-cli
)

if [[ "$do_nvidia" == "y" ]]; then
    pacman_packages+=(nvidia-utils lib32-nvidia-utils lib32-libxcrypt-compat)
fi

sudo pacman -S --needed --noconfirm "${pacman_packages[@]}" || warn "Some pacman packages may have failed."

# AUR packages (prefer yay, fall back to paru)
info "Installing AUR packages..."
aur_helper=""
if command -v yay &>/dev/null; then
    aur_helper="yay"
elif command -v paru &>/dev/null; then
    aur_helper="paru"
else
    warn "No AUR helper found (yay/paru). Skipping AUR packages."
fi

if [[ -n "$aur_helper" ]]; then
    aur_packages=(freetube-bin librewolf-bin)
    $aur_helper -S --needed --noconfirm "${aur_packages[@]}" || warn "Some AUR packages may have failed."
fi

# Remove fzf if installed
if pacman -Qi fzf &>/dev/null; then
    info "Removing fzf..."
    sudo pacman -Rns --noconfirm fzf || warn "Failed to remove fzf."
fi

# Flatpak
info "Installing flatpak packages..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

flatpak_packages=(
    com.rtosta.zapzap
    it.mijorus.gearlever
)
for pkg in "${flatpak_packages[@]}"; do
    flatpak install -y flathub "$pkg" 2>/dev/null || warn "Failed to install flatpak: $pkg"
done

# ─── Build Claude Desktop ────────────────────────────────────────────────────

info "Building Claude Desktop AppImage..."
claude_tmp="$(mktemp -d)"
if git clone https://github.com/aaddrick/claude-desktop-debian.git "$claude_tmp/claude-desktop-debian" 2>/dev/null; then
    pushd "$claude_tmp/claude-desktop-debian" > /dev/null
    if ./build.sh --build appimage 2>/dev/null; then
        mkdir -p "$HOME/Downloads"
        cp ./*.AppImage "$HOME/Downloads/" 2>/dev/null && ok "Claude Desktop AppImage copied to ~/Downloads/"
    else
        warn "Claude Desktop build failed. You can build it manually later."
    fi
    popd > /dev/null
else
    warn "Failed to clone Claude Desktop repo. You can build it manually later."
fi
rm -rf "$claude_tmp"

# ─── Deploy config files ─────────────────────────────────────────────────────

info "Deploying config files..."

backup_ts="$(date +%s)"

deploy() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then
        cp "$dest" "${dest}.bak.${backup_ts}"
    fi
    cp "$src" "$dest"
}

# Static files
deploy "$CONFIG_DIR/inputrc"                  "$HOME/.inputrc"
deploy "$CONFIG_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
deploy "$CONFIG_DIR/hypr/autostart.conf"      "$HOME/.config/hypr/autostart.conf"
deploy "$CONFIG_DIR/hypr/bindings.conf"       "$HOME/.config/hypr/bindings.conf"
deploy "$CONFIG_DIR/hypr/envs.conf"           "$HOME/.config/hypr/envs.conf"
deploy "$CONFIG_DIR/hypr/hypridle.conf"       "$HOME/.config/hypr/hypridle.conf"
deploy "$CONFIG_DIR/hypr/hyprland.conf"       "$HOME/.config/hypr/hyprland.conf"
deploy "$CONFIG_DIR/waybar/config.jsonc"      "$HOME/.config/waybar/config.jsonc"

# Template files (will be substituted below)
deploy "$CONFIG_DIR/bashrc"                   "$HOME/.bashrc"
deploy "$CONFIG_DIR/hypr/input.conf"          "$HOME/.config/hypr/input.conf"
deploy "$CONFIG_DIR/hypr/monitors.conf"       "$HOME/.config/hypr/monitors.conf"
deploy "$CONFIG_DIR/mako/config"              "$HOME/.config/mako/config"

# VSCode / Cursor settings
for editor_dir in "$HOME/.config/Code/User" "$HOME/.config/Cursor/User"; do
    if [[ -d "$(dirname "$editor_dir")" ]]; then
        deploy "$CONFIG_DIR/settings.json" "$editor_dir/settings.json"
    fi
done

ok "Config files deployed."

# ─── Template substitution ───────────────────────────────────────────────────

info "Applying template values..."

# bashrc
sed -i "s|{{SSH_KEY}}|${ssh_key}|g"   "$HOME/.bashrc"
sed -i "s|{{SSH_USER}}|${ssh_user}|g" "$HOME/.bashrc"
sed -i "s|{{SSH_HOST}}|${ssh_host}|g" "$HOME/.bashrc"
sed -i "s|{{VPN_CA}}|${vpn_ca}|g"     "$HOME/.bashrc"
sed -i "s|{{VPN_US}}|${vpn_us}|g"     "$HOME/.bashrc"

# hypr/input.conf - keyboard options
if [[ -n "$kb_options" ]]; then
    sed -i "s|{{KB_OPTIONS}}|${kb_options}|g" "$HOME/.config/hypr/input.conf"
else
    sed -i "s|  kb_options = {{KB_OPTIONS}}|  # kb_options = (standard PC keybinds)|g" "$HOME/.config/hypr/input.conf"
fi

# hypr/monitors.conf - workspace assignments
monitors_file="$HOME/.config/hypr/monitors.conf"
if [[ -n "$workspace_assignments" ]]; then
    tmp_monitors=$(mktemp)
    while IFS= read -r line; do
        if [[ "$line" == *"{{WORKSPACE_ASSIGNMENTS}}"* ]]; then
            printf '%s' "$workspace_assignments"
        else
            printf '%s\n' "$line"
        fi
    done < "$monitors_file" > "$tmp_monitors"
    mv "$tmp_monitors" "$monitors_file"
else
    sed -i '/{{WORKSPACE_ASSIGNMENTS}}/d' "$monitors_file"
fi

# mako/config - notification monitor
if [[ -n "$mako_output" ]]; then
    sed -i "s|{{MAKO_OUTPUT}}|${mako_output}|g" "$HOME/.config/mako/config"
else
    sed -i '/# Monitor output/d'    "$HOME/.config/mako/config"
    sed -i '/{{MAKO_OUTPUT}}/d'      "$HOME/.config/mako/config"
fi

ok "Templates applied."

# ─── Patch .desktop files ────────────────────────────────────────────────────

info "Patching .desktop files..."
desktop_dir="$HOME/.local/share/applications"

patch_desktop() {
    local file="$1" new_exec="$2"
    if [[ ! -f "$desktop_dir/$file" ]]; then
        warn "$file not found, skipping."
        return
    fi
    if grep -q "^Exec=${new_exec}" "$desktop_dir/$file"; then
        ok "$file already patched."
        return
    fi
    sed -i "s|^Exec=.*|#&\nExec=${new_exec}|" "$desktop_dir/$file"
    ok "Patched $file"
}

patch_desktop "Discord.desktop"  "vesktop"
patch_desktop "WhatsApp.desktop" "flatpak run com.rtosta.zapzap"
patch_desktop "GitHub.desktop"   "librewolf --new-window https://github.com/"

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo "  Remaining manual steps:"
echo ""
echo "  - Open GearLever and drag in the Claude Desktop AppImage:"
echo "      flatpak run it.mijorus.gearlever"
echo "      (AppImage is in ~/Downloads/)"
echo ""
echo "  - Run protonup-qt to add Proton GE for Steam:"
echo "      protonup-qt"
echo ""
echo "  - Steam launch options:"
echo "      Deadlock:    DXVK_ASYNC=1 VKD3D_DEBUG=none %command%"
echo "      Elden Ring:  unset SDL_VIDEODRIVER; %command%"
echo ""
echo "  - Obsidian: Settings -> Editor -> disable 'Readable line length'"
echo ""
echo "  - IDE: Settings -> search 'files.exclude' -> add __pycache__ etc."
echo ""
echo "  - Relaunch Hyprland: Super+Esc -> Relaunch"
echo ""
