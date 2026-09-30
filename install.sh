#!/usr/bin/env bash
# Security Headers Core Universal Installer (Bash for macOS / Linux)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/MosaabGalmod/security-headers-core/main/install.sh | bash
# or run locally:
#   ./install.sh [all|antigravity|claude|cursor|project]

set -e

TARGET="${1:-all}"
BASE_URL="https://raw.githubusercontent.com/MosaabGalmod/security-headers-core/main"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"

echo "=========================================================="
echo "  Security Headers Core: HTTP Security & CSP Agent Skill Setup"
echo "=========================================================="

fetch_and_install() {
    local dest_dir="$1"
    mkdir -p "$dest_dir/reference"
    local files=(
        "SKILL.md"
        "reference/csp-deep-dive.md"
        "reference/isolation-and-cookies.md"
        "reference/server-configs.md"
    )
    for f in "${files[@]}"; do
        if [ -n "$LOCAL_DIR" ] && [ -f "$LOCAL_DIR/$f" ]; then
            cp "$LOCAL_DIR/$f" "$dest_dir/$f"
        else
            curl -fsSL "$BASE_URL/$f" -o "$dest_dir/$f"
        fi
    done
}

# 1. Antigravity & Gemini CLI
if [ "$TARGET" = "all" ] || [ "$TARGET" = "antigravity" ] || [ "$TARGET" = "gemini" ]; then
    AGY_DIR="$HOME/.gemini/config/skills/security-headers-core"
    fetch_and_install "$AGY_DIR"
    echo "[OK] Installed to Antigravity / Gemini CLI: $AGY_DIR"
fi

# 2. Claude Code
if [ "$TARGET" = "all" ] || [ "$TARGET" = "claude" ]; then
    CLAUDE_DIR="$HOME/.claude/skills/security-headers-core"
    fetch_and_install "$CLAUDE_DIR"
    echo "[OK] Installed to Claude Code Skill: $CLAUDE_DIR"
fi

# 3. Project rules (Cursor / Windsurf)
if [ "$TARGET" = "all" ] || [ "$TARGET" = "project" ] || [ "$TARGET" = "cursor" ]; then
    mkdir -p ".cursor/rules"
    if [ -n "$LOCAL_DIR" ] && [ -f "$LOCAL_DIR/SKILL.md" ]; then
        cp "$LOCAL_DIR/SKILL.md" ".cursor/rules/security-headers-core.mdc"
    else
        curl -fsSL "$BASE_URL/SKILL.md" -o ".cursor/rules/security-headers-core.mdc"
    fi
    echo "[OK] Generated Cursor rule: .cursor/rules/security-headers-core.mdc"
fi

echo "Setup complete! security-headers-core is active."
