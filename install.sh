#!/usr/bin/env bash
set -e

# ================================================
# Inspire Git Toolkit - Installer
# Supports: install / update / uninstall
# ================================================

VERSION="1.1.0"
URL="https://raw.githubusercontent.com/parthivendra/inspire-git-toolkit/main/inspire-git-toolkit.sh"
DEST="$HOME/.local/share/inspire-git-toolkit.sh"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ── Detect shell config ──────────────────────────
if [[ "$SHELL" == *"zsh" ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

SOURCE_LINE="source $DEST"

# =================================================
# 🧹 UNINSTALL MODE
# =================================================
if [[ "$1" == "--uninstall" ]]; then
    echo -e "${RED}🧹 Uninstalling Inspire Git Toolkit...${RESET}"

    rm -f "$DEST"

    if grep -Fxq "$SOURCE_LINE" "$SHELL_RC" 2>/dev/null; then
        grep -Fxv "$SOURCE_LINE" "$SHELL_RC" > "${SHELL_RC}.tmp"
        mv "${SHELL_RC}.tmp" "$SHELL_RC"
        echo -e "${GREEN}✅ Removed from ${SHELL_RC}${RESET}"
    fi

    echo -e "${GREEN}✔ Uninstalled successfully.${RESET}"
    echo -e "Reload shell: ${CYAN}source $SHELL_RC${RESET}"
    exit 0
fi

# =================================================
# 📥 INSTALL / UPDATE
# =================================================

echo -e "${CYAN}📥 Inspire Git Toolkit v${VERSION}${RESET}"

# Dependency check
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}❌ curl is required but not installed.${RESET}"
    exit 1
fi

mkdir -p "$(dirname "$DEST")"

if [[ -f "$DEST" ]]; then
    echo -e "${YELLOW}🔄 Updating existing installation...${RESET}"
else
    echo -e "${GREEN}✨ Fresh installation...${RESET}"
fi

curl -fsSL "$URL" -o "$DEST"
chmod +x "$DEST"

# Add source safely
if ! grep -Fxq "$SOURCE_LINE" "$SHELL_RC" 2>/dev/null; then
    echo "$SOURCE_LINE" >> "$SHELL_RC"
    echo -e "${GREEN}✅ Added to ${SHELL_RC}${RESET}"
else
    echo -e "${YELLOW}⚠️  Already configured in ${SHELL_RC}${RESET}"
fi

echo -e "${GREEN}🚀 Installation complete!${RESET}"
echo ""
echo -e "Reload shell:"
echo -e "   ${CYAN}source $SHELL_RC${RESET}"
echo ""
echo -e "Try:"
echo -e "   ${CYAN}gs${RESET}   → pretty status"
echo -e "   ${CYAN}gqa${RESET}  → smart auto-commit"
echo -e "   ${CYAN}gq${RESET}   → quick commit"
echo ""
echo -e "Manage toolkit:"
echo -e "   ${CYAN}inspire update${RESET}"
echo -e "   ${CYAN}inspire uninstall${RESET}"
