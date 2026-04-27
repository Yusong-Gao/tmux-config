#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== dotfiles installer ==="

# ---------- 依赖安装 ----------
install_deps() {
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y tmux xclip fzf
    elif command -v yum &>/dev/null; then
        sudo yum install -y tmux xclip fzf
    elif command -v brew &>/dev/null; then
        brew install tmux fzf
    else
        echo "[WARN] Unknown package manager, please install tmux/xclip/fzf manually"
    fi
}

# 检查缺少的依赖
missing=()
for cmd in tmux fzf; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
done
# xclip 只在 Linux 上需要
if [[ "$(uname)" == "Linux" ]] && ! command -v xclip &>/dev/null; then
    missing+=("xclip")
fi

if [ ${#missing[@]} -gt 0 ]; then
    echo "[INFO] Missing: ${missing[*]}"
    read -p "Install dependencies? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        install_deps
    fi
fi

# ---------- 备份已有配置 ----------
backup_if_exists() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
        echo "[BACKUP] $file -> $backup"
        mv "$file" "$backup"
    elif [ -L "$file" ]; then
        rm "$file"
    fi
}

# ---------- 创建软链接 ----------
echo "[LINK] tmux.conf"
backup_if_exists "$HOME/.tmux.conf"
ln -s "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

echo "[LINK] tmux-copy.sh"
backup_if_exists "$HOME/.tmux-copy.sh"
ln -s "$DOTFILES_DIR/tmux/tmux-copy.sh" "$HOME/.tmux-copy.sh"
chmod +x "$DOTFILES_DIR/tmux/tmux-copy.sh"

echo "[LINK] tmux-url.sh"
backup_if_exists "$HOME/.tmux-url.sh"
ln -s "$DOTFILES_DIR/tmux/tmux-url.sh" "$HOME/.tmux-url.sh"
chmod +x "$DOTFILES_DIR/tmux/tmux-url.sh"

echo "[LINK] vimrc"
backup_if_exists "$HOME/.vimrc"
ln -s "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"

# ---------- 安装 TPM ----------
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "[INSTALL] TPM (Tmux Plugin Manager)"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ---------- systemd 开机自启（仅 Linux） ----------
if [[ "$(uname)" == "Linux" ]] && command -v systemctl &>/dev/null; then
    echo "[SETUP] systemd tmux auto-start"
    mkdir -p "$HOME/.config/systemd/user"
    cp "$DOTFILES_DIR/systemd/tmux.service" "$HOME/.config/systemd/user/tmux.service"
    systemctl --user daemon-reload
    mkdir -p "$HOME/.config/systemd/user/default.target.wants"
    ln -sf "$HOME/.config/systemd/user/tmux.service" "$HOME/.config/systemd/user/default.target.wants/tmux.service"
    sudo loginctl enable-linger "$(whoami)" 2>/dev/null || echo "[WARN] enable-linger failed, tmux may not auto-start on boot"
    echo "[OK] tmux will auto-start on boot"
fi

# ---------- 重载 tmux ----------
if tmux info &>/dev/null; then
    tmux source-file "$HOME/.tmux.conf" 2>/dev/null && echo "[OK] tmux config reloaded"
fi

# ---------- 安装 tmux 插件 ----------
if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    echo "[INSTALL] tmux plugins"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

echo ""
echo "=== Done! ==="
echo "Start tmux:  tmux new -s main"
