#!/usr/bin/env bash
set -euo pipefail

# CC Toolkit — Project Updater
# Syncs templates (commands, agents, rules, hooks) from cc-toolkit into an existing project.
# Does NOT overwrite: CLAUDE.md, settings.json, settings.local.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-.}"
CLAUDE_DIR="$PROJECT_DIR/.claude"

# Colors
if [ -t 1 ]; then
  GREEN='\033[0;32m' YELLOW='\033[0;33m' CYAN='\033[0;36m' BOLD='\033[1m' DIM='\033[2m' NC='\033[0m'
else
  GREEN='' YELLOW='' CYAN='' BOLD='' DIM='' NC=''
fi

info()    { echo -e "  ${CYAN}ℹ${NC}  $1"; }
success() { echo -e "  ${GREEN}✓${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
step()    { echo -e "  ${CYAN}→${NC}  ${BOLD}$1${NC}"; }

echo ""
echo -e "${BOLD}${CYAN}  CC Toolkit — Update${NC}"
echo ""

# Verify this is an existing cc-toolkit project
if [ ! -d "$CLAUDE_DIR" ]; then
  warn "No .claude/ directory found in $PROJECT_DIR"
  warn "Run ccinit first to scaffold a new project."
  exit 1
fi

if [ ! -d "$SCRIPT_DIR/templates" ]; then
  warn "No templates directory found in $SCRIPT_DIR"
  warn "Your cc-toolkit installation may be incomplete."
  exit 1
fi

# Track counts
added=0
updated=0
skipped=0

# Sync a template directory into the project
# Usage: sync_dir <template_subdir> <target_subdir>
sync_dir() {
  local src="$SCRIPT_DIR/templates/$1"
  local dst="$CLAUDE_DIR/$2"

  if [ ! -d "$src" ]; then
    return
  fi

  mkdir -p "$dst"
  step "Syncing $2/..."

  for file in "$src"/*; do
    [ -f "$file" ] || continue
    local name
    name=$(basename "$file")
    local target="$dst/$name"

    if [ ! -f "$target" ]; then
      cp "$file" "$target"
      success "Added $2/$name"
      added=$((added + 1))
    elif ! diff -q "$file" "$target" &>/dev/null; then
      cp "$file" "$target"
      success "Updated $2/$name"
      updated=$((updated + 1))
    else
      skipped=$((skipped + 1))
    fi
  done
}

sync_dir "commands" "commands"
sync_dir "agents" "agents"
sync_dir "rules" "rules"
sync_dir "hooks" "hooks"

# Make hook scripts executable
chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true

echo ""
if [ $added -eq 0 ] && [ $updated -eq 0 ]; then
  success "Already up to date. ${DIM}($skipped files unchanged)${NC}"
else
  success "Done! ${BOLD}$added added${NC}, ${BOLD}$updated updated${NC}, ${DIM}$skipped unchanged${NC}"
fi
echo ""
