#!/usr/bin/env bash
set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CC Toolkit Installer
# Install: curl -fsSL https://raw.githubusercontent.com/squirrelsoft-dev/cc-toolkit/main/install.sh | bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

VERSION="1.0.0"
REPO="squirrelsoft-dev/cc-toolkit"
BRANCH="main"
INSTALL_DIR="${CC_TOOLKIT_DIR:-$HOME/cc-toolkit}"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"

# Colors (if terminal supports them)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  DIM='\033[2m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' NC=''
fi

print_banner() {
  echo ""
  echo -e "${BOLD}${CYAN}  ┌─────────────────────────────────────┐${NC}"
  echo -e "${BOLD}${CYAN}  │     CC Toolkit Installer v${VERSION}      │${NC}"
  echo -e "${BOLD}${CYAN}  │   Lightweight Claude Code Setup     │${NC}"
  echo -e "${BOLD}${CYAN}  └─────────────────────────────────────┘${NC}"
  echo ""
}

info()    { echo -e "  ${BLUE}ℹ${NC}  $1"; }
success() { echo -e "  ${GREEN}✓${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "  ${RED}✗${NC}  $1"; }
step()    { echo -e "  ${CYAN}→${NC}  ${BOLD}$1${NC}"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Preflight checks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

preflight() {
  local missing=()

  command -v git    &>/dev/null || missing+=("git")
  command -v curl   &>/dev/null || missing+=("curl")

  if [ ${#missing[@]} -gt 0 ]; then
    error "Missing required tools: ${missing[*]}"
    echo "  Install them and try again."
    exit 1
  fi

  # Check if Claude Code is installed
  if ! command -v claude &>/dev/null; then
    warn "Claude Code CLI not found. Install it from https://docs.claude.com"
    warn "Continuing anyway — the toolkit will be ready when you install Claude Code."
    echo ""
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Download toolkit
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

download_toolkit() {
  local is_update=false

  if [ -d "$INSTALL_DIR" ]; then
    is_update=true
    step "Updating CC Toolkit in $INSTALL_DIR..."
  else
    step "Downloading CC Toolkit to $INSTALL_DIR..."
  fi

  # Clone to a temp directory, then sync into INSTALL_DIR
  local tmp_dir="$INSTALL_DIR.tmp"
  rm -rf "$tmp_dir"

  if git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$tmp_dir" 2>/dev/null; then
    rm -rf "$tmp_dir/.git"
  else
    info "Git clone failed, falling back to direct download..."
    mkdir -p "$tmp_dir"

    # Download the repo as a tarball and extract
    if curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" -o "$tmp_dir/archive.tar.gz" 2>/dev/null; then
      tar -xzf "$tmp_dir/archive.tar.gz" -C "$tmp_dir" --strip-components=1
      rm -f "$tmp_dir/archive.tar.gz"
    else
      error "Download failed. Try cloning manually:"
      echo ""
      echo "    git clone https://github.com/$REPO.git ~/cc-toolkit"
      echo ""
      rm -rf "$tmp_dir"
      exit 1
    fi
  fi

  # Sync: replace toolkit files, preserve nothing user-specific in INSTALL_DIR
  # (user customizations live in each project's .claude/, not here)
  if [ "$is_update" = true ]; then
    # Remove old files and copy new ones in
    rm -rf "$INSTALL_DIR"
  fi

  mv "$tmp_dir" "$INSTALL_DIR"

  chmod +x "$INSTALL_DIR/init.sh" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/install.sh" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/update.sh" 2>/dev/null || true

  if [ "$is_update" = true ]; then
    success "Updated to latest version"
  else
    success "Downloaded successfully"
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Shell integration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

setup_shell() {
  step "Setting up shell integration..."

  local shell_rc=""
  local shell_name=""

  if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "$SHELL" 2>/dev/null)" = "zsh" ]; then
    shell_rc="$HOME/.zshrc"
    shell_name="zsh"
  elif [ -n "${BASH_VERSION:-}" ] || [ "$(basename "$SHELL" 2>/dev/null)" = "bash" ]; then
    shell_rc="$HOME/.bashrc"
    shell_name="bash"
    # macOS uses .bash_profile for login shells
    if [[ "$OSTYPE" == "darwin"* ]] && [ -f "$HOME/.bash_profile" ]; then
      shell_rc="$HOME/.bash_profile"
    fi
  elif [ "$(basename "$SHELL" 2>/dev/null)" = "fish" ]; then
    shell_rc="$HOME/.config/fish/config.fish"
    shell_name="fish"
  fi

  if [ -z "$shell_rc" ]; then
    warn "Could not detect shell. Add this to your shell config manually:"
    echo ""
    echo "    export CC_TOOLKIT_DIR=\"$INSTALL_DIR\""
    echo "    source \"$INSTALL_DIR/shell-aliases.sh\""
    echo ""
    return
  fi

  # Check if already added
  if grep -q "cc-toolkit" "$shell_rc" 2>/dev/null; then
    info "Shell integration already present in $shell_rc"
    return
  fi

  # Fish shell has different syntax
  if [ "$shell_name" = "fish" ]; then
    mkdir -p "$(dirname "$shell_rc")"
    cat >> "$shell_rc" << FISH

# CC Toolkit — Claude Code project scaffolding
set -gx CC_TOOLKIT_DIR "$INSTALL_DIR"
source "$INSTALL_DIR/shell-aliases.sh"
FISH
  else
    cat >> "$shell_rc" << SHELLRC

# CC Toolkit — Claude Code project scaffolding
export CC_TOOLKIT_DIR="$INSTALL_DIR"
source "$INSTALL_DIR/shell-aliases.sh"
SHELLRC
  fi

  success "Added to $shell_rc"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Optional: Install security tools
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

detect_package_manager() {
  if command -v brew &>/dev/null; then
    echo "brew"
  elif command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "none"
  fi
}

# Prefer uvx > pipx > pip3 for Python CLI tools
install_python_tool() {
  local tool="$1"
  if command -v uvx &>/dev/null; then
    uv tool install "$tool" --quiet 2>/dev/null && success "done (uv)" && return 0
  fi
  if command -v pipx &>/dev/null; then
    pipx install "$tool" --quiet 2>/dev/null && success "done (pipx)" && return 0
  fi
  if command -v pip3 &>/dev/null; then
    pip3 install "$tool" --quiet 2>/dev/null && success "done (pip)" && return 0
  fi
  return 1
}

install_security_tools() {
  step "Checking security & analysis tools..."
  echo ""

  # Show detected installers
  local py_installer="none"
  if command -v uvx &>/dev/null; then
    py_installer="uv"
  elif command -v pipx &>/dev/null; then
    py_installer="pipx"
  elif command -v pip3 &>/dev/null; then
    py_installer="pip3"
  fi
  info "Python tool installer: ${BOLD}$py_installer${NC}  |  System: ${BOLD}$(detect_package_manager)${NC}"
  echo ""

  local tools_available=()
  local tools_missing=()

  # Check each tool
  tool_description() {
    case "$1" in
      gitleaks) echo "Secret detection — finds API keys, tokens, passwords in code" ;;
      semgrep)  echo "SAST scanner — injection, XSS, OWASP Top 10" ;;
      trivy)    echo "Vulnerability scanner — deps, containers, IaC" ;;
      oxlint)   echo "Fast linter — 100x faster than ESLint" ;;
    esac
  }

  for tool in gitleaks semgrep trivy oxlint; do
    if command -v "$tool" &>/dev/null; then
      tools_available+=("$tool")
      success "$tool ${DIM}(installed)${NC}"
    else
      tools_missing+=("$tool")
      info "$tool ${DIM}— $(tool_description "$tool")${NC}"
    fi
  done

  # Also check npm-based tools
  if command -v npx &>/dev/null; then
    for tool in knip madge; do
      if npx --yes "$tool" --help &>/dev/null 2>&1; then
        success "$tool ${DIM}(available via npx)${NC}"
      else
        info "$tool ${DIM}— available via npx on demand${NC}"
      fi
    done
  fi

  echo ""

  if [ ${#tools_missing[@]} -eq 0 ]; then
    success "All recommended tools are installed!"
    return
  fi

  read -rp "  Install missing tools? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    info "Skipped. You can install them later — hooks will gracefully skip missing tools."
    return
  fi

  local pkg_mgr
  pkg_mgr=$(detect_package_manager)

  for tool in "${tools_missing[@]}"; do
    echo -ne "  Installing ${BOLD}$tool${NC}... "

    case "$tool" in
      gitleaks)
        case "$pkg_mgr" in
          brew)   brew install gitleaks 2>/dev/null && success "done" || warn "failed" ;;
          apt)    echo "  → Download from https://github.com/gitleaks/gitleaks/releases"; warn "manual install needed" ;;
          *)      echo "  → Download from https://github.com/gitleaks/gitleaks/releases"; warn "manual install needed" ;;
        esac
        ;;
      semgrep)
        if ! install_python_tool semgrep; then
          if command -v brew &>/dev/null; then
            brew install semgrep 2>/dev/null && success "done (brew)" || warn "failed"
          else
            warn "Install via: uv tool install semgrep"
          fi
        fi
        ;;
      trivy)
        case "$pkg_mgr" in
          brew)   brew install trivy 2>/dev/null && success "done" || warn "failed" ;;
          apt)    warn "Install via: https://aquasecurity.github.io/trivy/latest/getting-started/installation/" ;;
          *)      warn "Install via: https://trivy.dev" ;;
        esac
        ;;
      oxlint)
        if command -v npm &>/dev/null; then
          npm install -g oxlint 2>/dev/null && success "done" || warn "failed"
        else
          warn "Install via: npm install -g oxlint"
        fi
        ;;
    esac
  done

  echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Finish
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_next_steps() {
  echo ""
  echo -e "${BOLD}${GREEN}  ✅ CC Toolkit installed successfully!${NC}"
  echo ""
  echo -e "  ${BOLD}Quick Start:${NC}"
  echo ""
  echo -e "    ${CYAN}1.${NC} Reload your shell:"
  echo -e "       ${DIM}source ~/.zshrc${NC}  ${DIM}# or restart terminal${NC}"
  echo ""
  echo -e "    ${CYAN}2.${NC} Scaffold a project:"
  echo -e "       ${DIM}cd your-project${NC}"
  echo -e "       ${DIM}ccinit${NC}"
  echo ""
  echo -e "    ${CYAN}3.${NC} Launch Claude Code:"
  echo -e "       ${DIM}cc${NC}"
  echo ""
  echo -e "  ${BOLD}Useful Aliases:${NC}"
  echo ""
  echo -e "    ${CYAN}cc${NC}       Launch Claude Code"
  echo -e "    ${CYAN}ccinit${NC}   Scaffold .claude/ for current project"
  echo -e "    ${CYAN}h${NC}        Quick task with Haiku (cheap/fast)"
  echo -e "    ${CYAN}cx${NC}       Auto-pilot mode (skip permissions)"
  echo -e "    ${CYAN}cr${NC}       Resume last session"
  echo -e "    ${CYAN}review${NC}   Review git diff with Claude"
  echo -e "    ${CYAN}gcm${NC}      Generate commit message from staged changes"
  echo ""
  echo -e "  ${BOLD}Docs:${NC} https://github.com/$REPO"
  echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
  print_banner
  preflight

  local is_update=false
  [ -d "$INSTALL_DIR" ] && is_update=true

  download_toolkit

  if [ "$is_update" = true ]; then
    success "CC Toolkit updated! Reload your shell:"
    echo ""
    echo -e "    ${DIM}source ~/.zshrc${NC}"
    echo ""
  else
    setup_shell
    install_security_tools
    print_next_steps
  fi
}

main
