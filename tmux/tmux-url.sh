#!/bin/bash
# tmux URL 提取：支持跨行 URL 拼接

# 抓取当前 pane 最近 5000 行，-J 先合并软换行
content=$(tmux capture-pane -J -p -S -5000)

urls=$(echo "$content" \
    | tr '\n' ' ' \
    | grep -oP 'https?://[^\s"<>)\]]+' \
    | sed 's/[.,;:!?)]*$//' \
    | sort -u)

if [ -z "$urls" ]; then
    tmux display-message "No URLs found"
    exit 0
fi

selected=$(echo "$urls" | fzf-tmux --prompt='Open URL> ' --no-sort)

if [ -z "$selected" ]; then
    exit 0
fi

# 判断环境：有 DISPLAY 用 xdg-open，否则用 OSC 8 或复制到剪贴板
if [ -n "$DISPLAY" ] && command -v xdg-open &>/dev/null; then
    xdg-open "$selected" 2>/dev/null &
elif command -v open &>/dev/null; then
    open "$selected" 2>/dev/null &
else
    # SSH 远程环境：复制 URL 到剪贴板，方便在 Mac 端粘贴打开
    printf '%s' "$selected" | ~/.tmux-copy.sh
    tmux display-message "URL copied: $selected"
    exit 0
fi

tmux display-message "Opening: $selected"
