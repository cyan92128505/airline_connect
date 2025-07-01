#!/bin/bash
# notify.sh - 跨平台通知工具

# Usage: ./notify.sh "標題" "訊息內容"
title="${1:-任務通知}"
message="${2:-任務已完成}"

# Detect OS
case "$(uname -s)" in
    Darwin*)    # macOS
        osascript -e "display notification \"$message\" with title \"$title\""
        afplay /System/Library/Sounds/Hero.aiff
        ;;
    Linux*)     # Linux
        if command -v notify-send > /dev/null; then
            notify-send "$title" "$message"
        else
            echo -e "\a"  # Fallback to bell
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)  # Windows
        powershell -c "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); \$n = New-Object System.Windows.Forms.NotifyIcon; \$n.Icon = [System.Drawing.SystemIcons]::Information; \$n.BalloonTipTitle = '$title'; \$n.BalloonTipText = '$message'; \$n.Visible = \$true; \$n.ShowBalloonTip(5000)"
        ;;
    *)
        echo -e "\a"  # Fallback to bell for unknown OS
        ;;
esac