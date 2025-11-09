#!/bin/bash
# Restart the R backend server

echo "Restarting R backend server..."

# Stop server via tmux if running
/opt/homebrew/bin/tmux send-keys -t fw:8 C-c 2>/dev/null
sleep 1

# Reload package and restart
/opt/homebrew/bin/tmux send-keys -t fw:8 'devtools::load_all()' Enter
sleep 2
/opt/homebrew/bin/tmux send-keys -t fw:8 'gui(browse = FALSE)' Enter

echo "✅ Server restarted!"
