#!/bin/sh
# Paste script - sends Shift+Insert for terminals, Ctrl+V otherwise

sleep 0.05

app_id=$(niri msg focused-window | grep 'App ID:' | sed 's/.*App ID: "\(.*\)"/\1/')

case "$app_id" in
    org.wezfurlong.wezterm|Alacritty|kitty|foot|ghostty)
        wtype -M shift -k Insert -m shift
        ;;
    *)
        wtype -M ctrl -k v -m ctrl
        ;;
esac
