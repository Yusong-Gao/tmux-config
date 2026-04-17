#!/bin/bash
# tmux 复制脚本：自动适配本地 X11 和 SSH 远程（OSC 52）

input=$(cat)

# 如果当前没有 DISPLAY，尝试从 tmux 环境获取
if [ -z "$DISPLAY" ]; then
    DISPLAY=$(tmux show-environment DISPLAY 2>/dev/null | sed 's/^DISPLAY=//')
    export DISPLAY
fi

# 有 DISPLAY + xclip → 用 xclip 写系统剪贴板
if [ -n "$DISPLAY" ] && command -v xclip &>/dev/null; then
    printf '%s' "$input" | xclip -selection clipboard -i
    printf '%s' "$input" | xclip -selection primary -i
else
    # SSH 远程（无 DISPLAY）→ 用 OSC 52 写终端剪贴板（iTerm2 支持）
    encoded=$(printf '%s' "$input" | base64 -w 0)
    tty_path=$(tmux display-message -p '#{pane_tty}')
    if [ -n "$tty_path" ] && [ -w "$tty_path" ]; then
        printf '\033]52;c;%s\a' "$encoded" > "$tty_path"
    fi
fi
