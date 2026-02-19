#!/usr/bin/env bash
# CC Toolkit — Shell Aliases
# Source this in ~/.zshrc or ~/.bashrc:
#   source ~/cc-toolkit/shell-aliases.sh

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Claude Code shortcuts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Core launchers
alias cc="claude"                                         # General shortcut
alias h="claude --model haiku"                            # Quick/cheap tasks
alias cr="claude --resume"                                # Resume last session

# One-shot (non-interactive, pipe-friendly)
alias cp="claude -p"                                      # Print mode
alias hp="claude -p --model haiku"                        # Print mode with Haiku
alias cj="claude -p --output-format json"                 # JSON output for scripting

# Auto-pilot (use in sandboxed/trusted environments only)
alias cx="claude --dangerously-skip-permissions"           # Full auto-pilot

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Context-loaded launchers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Launch with Mermaid diagrams injected (if you use the .memory/ai/diagrams pattern)
unalias cdi 2>/dev/null
cdi() {
  local diagrams_dir="${1:-.memory/ai/diagrams}"
  if [[ -d "$diagrams_dir" ]]; then
    claude --append-system-prompt "$(cat "$diagrams_dir"/**/*.md 2>/dev/null)"
  else
    echo "No diagrams directory found at $diagrams_dir"
    claude
  fi
}

# Launch with a specific context file
unalias cf 2>/dev/null
cf() {
  if [[ -f "$1" ]]; then
    claude --append-system-prompt "$(cat "$1")"
  else
    echo "File not found: $1"
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Git + Claude workflows
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Quick git diff review
unalias review 2>/dev/null
review() {
  git diff "${1:-HEAD}" | claude -p "Review this diff. Flag bugs, security issues, and suggest improvements. Be concise."
}

# Generate commit message from staged changes
unalias gcm 2>/dev/null
gcm() {
  git diff --cached | claude -p "Write a conventional commit message for this diff. Output ONLY the message, nothing else."
}

# Explain code from stdin
explain() {
  cat | claude -p "Explain this code concisely:"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Project scaffolding
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Scaffold a new project with cc-toolkit
unalias ccinit 2>/dev/null
ccinit() {
  local toolkit_dir="${CC_TOOLKIT_DIR:-$HOME/cc-toolkit}"
  if [[ -f "$toolkit_dir/init.sh" ]]; then
    bash "$toolkit_dir/init.sh" "${1:-.}"
  else
    echo "CC Toolkit not found. Set CC_TOOLKIT_DIR or install to ~/cc-toolkit"
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GitHub shortcuts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

alias ghv="gh repo view --web"
alias ghpr="gh pr view --web"
alias ghprl="gh pr list"
