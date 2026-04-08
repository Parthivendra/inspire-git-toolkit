#!/usr/bin/env bash
set -e

# ================================================
# Inspire Git Toolkit - One-click Installer
# ================================================

REPO="inspire-git-toolkit"
URL="https://raw.githubusercontent.com/parthivendra/inspire-git-toolkit/main/inspire-git-toolkit.sh"
DEST="$HOME/.local/share/inspire-git-toolkit.sh"

echo -e "\033[0;36m📥 Installing Inspire Git Toolkit...\033[0m"

# Create directory if it doesn't exist
mkdir -p "$(dirname "$DEST")"

# Download the main script
curl -fsSL "$URL" -o "$DEST"

# Add source line only if it's not already there
if ! grep -q "inspire-git-toolkit.sh" ~/.bashrc 2>/dev/null && \
   ! grep -q "inspire-git-toolkit.sh" ~/.zshrc 2>/dev/null; then
    
    echo "source $DEST" >> ~/.bashrc
    echo -e "\033[0;32m✅ Added to ~/.bashrc\033[0m"
else
    echo -e "\033[0;33m⚠️  Already installed in your shell config.\033[0m"
fi

echo -e "\033[0;32m🚀 Installation complete!\033[0m"
echo -e "   Run: \033[1msource ~/.bashrc\033[0m   (or restart your terminal)"
echo -e "   Try these commands:"
echo -e "     \033[1mgs\033[0m     → pretty status"
echo -e "     \033[1mgqa\033[0m    → smart auto-commit"
echo -e "     \033[1mgq\033[0m     → quick commit"
