#!/bin/sh
# Copy script - sends Ctrl+Shift+C for terminals, Ctrl+C otherwise

sleep 0.05

app_id=$(niri msg focused-window | grep 'App ID:' | sed 's/.*App ID: "\(.*\)"/\1/')

case "$app_id" in
    org.wezfurlong.wezterm|Alacritty|kitty|foot|ghostty)
        wtype -M ctrl -M shift -k c -m shift -m ctrl
        ;;
    *)
        wtype -M ctrl -k c -m ctrl
        ;;
esac
