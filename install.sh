#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Neusis Code Installer
#
# curl -fsSL https://get.neusis.ai/install.sh | sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

INSTALL_DIR="$HOME/.neusis/bin"
BINARY="$INSTALL_DIR/neusiscode"
CONFIG_DIR="$HOME/.config/neusiscode"
CONFIG_PATH="$CONFIG_DIR/neusiscode.json"
REPO="Neusis-AI-Org/neusis-code-releases"
NEURON_INSTALL_URL="https://neusis-ai-org.github.io/neusis-neuron-releases/install.sh"

# ── UI ────────────────────────────────────────────────────────────────────────

CYAN='\033[0;36m'; WHITE='\033[1;37m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'; GRAY='\033[0;90m'; NC='\033[0m'
STEP=0

banner() {
    echo ""
    printf "${CYAN}  ███╗   ██╗███████╗██╗   ██╗███████╗██╗███████╗${NC}\n"
    printf "${CYAN}  ████╗  ██║██╔════╝██║   ██║██╔════╝██║██╔════╝${NC}\n"
    printf "${CYAN}  ██╔██╗ ██║█████╗  ██║   ██║███████╗██║███████╗${NC}\n"
    printf "${CYAN}  ██║╚██╗██║██╔══╝  ██║   ██║╚════██║██║╚════██║${NC}\n"
    printf "${CYAN}  ██║ ╚████║███████╗╚██████╔╝███████║██║███████║${NC}\n"
    printf "${CYAN}  ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚══════╝╚═╝╚══════╝${NC}\n"
    echo ""
    printf "${WHITE}  C O D E   I N S T A L L E R${NC}\n"
    printf "${GRAY}  ─────────────────────────────────────────────────${NC}\n"
    echo ""
}

step()   { STEP=$((STEP+1)); printf "${GRAY}  [${NC}${WHITE}%s${NC}${GRAY}] ${NC}${WHITE}%s${NC}" "$STEP" "$1"; }
ok()     { printf "${GREEN}  ✓ %s${NC}\n" "$1"; }
warn()   { printf "${YELLOW}  ! %s${NC}\n" "$1"; }
detail() { printf "${GRAY}      %s${NC}\n" "$1"; }
divider(){ echo ""; printf "${GRAY}  ─────────────────────────────────────────────────${NC}\n"; echo ""; }
fatal()  { echo ""; printf "${RED}  ✗ ERROR: %s${NC}\n" "$1"; echo ""; exit 1; }

# ── Platform ──────────────────────────────────────────────────────────────────

detect_platform() {
    local os arch
    os="$(uname -s)"; arch="$(uname -m)"
    case "$os" in
        Darwin) OS_TAG="darwin" ;;
        Linux)  OS_TAG="linux"  ;;
        *)      fatal "Unsupported OS: $os  (supported: macOS, Linux)" ;;
    esac
    case "$arch" in
        x86_64)        ARCH_TAG="x64"   ;;
        aarch64|arm64) ARCH_TAG="arm64" ;;
        *)             fatal "Unsupported arch: $arch  (supported: x64, arm64)" ;;
    esac
    [ "$OS_TAG" = "linux" ] && EXT="tar.gz" || EXT="zip"
}

# ── Helpers ───────────────────────────────────────────────────────────────────

fetch() {
    if command -v curl &>/dev/null; then
        curl -sf "$1"
    elif command -v wget &>/dev/null; then
        wget -q -O- "$1"
    else
        fatal "curl or wget is required. Please install one and try again."
    fi
}

download() {
    local url="$1" dest="$2"
    if command -v curl &>/dev/null; then
        curl -fL -# -o "$dest" "$url"
    else
        wget -q -O "$dest" "$url"
    fi
}

# Fetch a URL to stdout via curl or wget; returns 127 if neither exists.
# Unlike fetch(), this never aborts — used for the optional neuron install.
fetch_optional() {
    if command -v curl &>/dev/null; then
        curl -fsSL "$1"
    elif command -v wget &>/dev/null; then
        wget -qO- "$1"
    else
        return 127
    fi
}

latest_version() {
    fetch "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed 's/.*"tag_name": *"v\([^"]*\)".*/\1/'
}

installed_version() {
    [ -x "$BINARY" ] || { echo ""; return; }
    "$BINARY" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

[ -z "${HOME:-}" ] && fatal "HOME is not set."
detect_platform
banner

# Step 1 — resolve version
step "Version"; echo ""
LATEST="$(latest_version 2>/dev/null)" || fatal "Could not reach GitHub. Check your internet connection."
[ -z "$LATEST" ] && fatal "Could not resolve latest version from GitHub Releases."
detail "Latest: v${LATEST}"

INSTALLED="$(installed_version)"
if [ -n "$INSTALLED" ] && [ "$INSTALLED" = "$LATEST" ]; then
    ok "Already up to date (v${LATEST})"
    echo ""
    exit 0
fi
[ -n "$INSTALLED" ] && detail "Installed: v${INSTALLED} → upgrading to v${LATEST}"

# Step 2 — download
step "Download"; echo ""
ARCHIVE="neusiscode-${OS_TAG}-${ARCH_TAG}.${EXT}"
URL="https://github.com/${REPO}/releases/download/v${LATEST}/${ARCHIVE}"
TMP="$(mktemp /tmp/neusiscode-XXXXXX)"
trap 'rm -f "$TMP"' EXIT
detail "${ARCHIVE}"
download "$URL" "$TMP" || fatal "Download failed. Manual download: https://github.com/${REPO}/releases"
ok "Downloaded"

# Step 3 — install binary
step "Install"; echo ""
mkdir -p "$INSTALL_DIR"
if [ "$EXT" = "tar.gz" ]; then
    tar -xzf "$TMP" -C "$INSTALL_DIR"
else
    unzip -o -q "$TMP" -d "$INSTALL_DIR"
fi
chmod +x "$BINARY"
ok "Installed  →  $BINARY"

# Step 4 — PATH
step "PATH"; echo ""

add_to_rc() {
    grep -qF "$INSTALL_DIR" "$1" 2>/dev/null && return 1
    printf '\n# Neusis Code\nexport PATH="$PATH:%s"\n' "$INSTALL_DIR" >> "$1"
}

if echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    ok "Already in PATH"
else
    UPDATED=""
    for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile"; do
        [ -f "$rc" ] && add_to_rc "$rc" && UPDATED="$UPDATED $(basename "$rc")"
    done
    [ -z "$UPDATED" ] && add_to_rc "$HOME/.profile" && UPDATED=" .profile"
    export PATH="$PATH:$INSTALL_DIR"
    ok "Added to PATH  →${UPDATED}"
fi

# Step 5 — config (always write latest format, preserve secrets if they exist)
step "Configuration"; echo ""
API_KEY=""
KB_REPO=""
NEURON_PAT=""
if [ -f "$CONFIG_PATH" ]; then
    # `|| true` is required: under `set -euo pipefail` on Apple's /bin/bash
    # (3.2.57), a no-match grep makes the pipeline exit 1, errexit fires on
    # the assignment, and the script silently exits at step 5. The KB_REPO
    # and NEURON_PAT lookups DO miss on every config written by v0.1.5 or
    # earlier (no mcp block) — that's the v0.1.6 install regression.
    API_KEY="$(grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_PATH" 2>/dev/null | head -1 | sed 's/.*"apiKey"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)"
    KB_REPO="$(grep -o '"--kb-repo"[[:space:]]*,[[:space:]]*"[^"]*"' "$CONFIG_PATH" 2>/dev/null | head -1 | sed 's/.*"--kb-repo"[[:space:]]*,[[:space:]]*"\([^"]*\)".*/\1/' || true)"
    NEURON_PAT="$(grep -o '"GITHUB_PERSONAL_ACCESS_TOKEN"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_PATH" 2>/dev/null | head -1 | sed 's/.*"GITHUB_PERSONAL_ACCESS_TOKEN"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)"
fi
if [ -z "$API_KEY" ]; then
    divider
    printf "${WHITE}  Authentication${NC}\n\n"
    printf "${GRAY}  API Key ${NC}${CYAN}▸ ${NC}"
    read -r API_KEY </dev/tty
    [ -z "${API_KEY:-}" ] && fatal "API key cannot be empty."
    echo ""
fi

# Project Brain — optional neusis-neuron MCP knowledge-base integration.
# kb-repo is per-project, so this is an opt-in prompt; blank skips it entirely.
if [ -z "$KB_REPO" ]; then
    divider
    printf "${WHITE}  Project Brain ${GRAY}(optional)${NC}\n\n"
    printf "${GRAY}  Connect a project-brain knowledge-base repo for richer context.${NC}\n"
    printf "${GRAY}  Leave blank to skip — you can add it to a project's${NC}\n"
    printf "${GRAY}  .neusiscode/neusiscode.jsonc later.${NC}\n\n"
    printf "${GRAY}  KB repo (owner/repo) ${NC}${CYAN}▸ ${NC}"
    read -r KB_REPO </dev/tty
    if [ -n "${KB_REPO:-}" ]; then
        printf "${GRAY}  GitHub token (fine-grained PAT, Contents:Read) ${NC}${CYAN}▸ ${NC}"
        read -r NEURON_PAT </dev/tty
    fi
    echo ""
fi

# Install the neusis-neuron MCP server when project-brain is configured.
# Non-fatal: a failure here must not break the Neusis Code install.
if [ -n "${KB_REPO:-}" ]; then
    detail "Installing neusis-neuron-mcp …"
    if fetch_optional "$NEURON_INSTALL_URL" | INSTALL_DIR="$INSTALL_DIR" bash >/dev/null 2>&1; then
        ok "neusis-neuron-mcp installed"
    elif command -v curl &>/dev/null || command -v wget &>/dev/null; then
        warn "neusis-neuron-mcp install failed — project-brain stays inactive until it is installed"
    else
        warn "curl or wget not found — skipped neusis-neuron-mcp install"
    fi
fi

# Build the optional mcp.neusis-neuron block (omitted entirely when no KB repo).
MCP_BLOCK=""
if [ -n "${KB_REPO:-}" ]; then
    NEURON_ENV=""
    if [ -n "${NEURON_PAT:-}" ]; then
        NEURON_ENV="
      \"environment\": { \"GITHUB_PERSONAL_ACCESS_TOKEN\": \"$NEURON_PAT\" },"
    fi
    MCP_BLOCK=",
  \"mcp\": {
    \"neusis-neuron\": {
      \"type\": \"local\",
      \"command\": [\"neusis-neuron-mcp\", \"stdio\", \"--kb-repo\", \"$KB_REPO\"],${NEURON_ENV}
      \"enabled\": true
    }
  }"
fi

mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_PATH" <<CONFIGEOF
{
  "\$schema": "https://neusis.ai/config.json",
  "model": "neusiscode/auto",
  "provider": {
    "neusiscode": {
      "options": {
        "apiKey": "$API_KEY"
      }
    }
  },
  "registry": {
    "repos": [{ "url": "https://github.com/Neusis-AI-Org/neusiscode-registry" }]
  },
  "disabled_providers": ["opencode", "github-copilot"]${MCP_BLOCK}
}
CONFIGEOF
ok "Configuration saved"
detail "$CONFIG_PATH"
[ -n "${KB_REPO:-}" ] && detail "project-brain bound to $KB_REPO (per-project override: .neusiscode/neusiscode.jsonc)"

# Done
divider
printf "${GREEN}  ✓ Neusis Code v${LATEST} ready!${NC}\n\n"
if [ -n "$INSTALLED" ]; then
    printf "${GRAY}  Updated: v${INSTALLED} → v${LATEST}${NC}\n"
else
    printf "${GRAY}  Open a new terminal and run:${NC}\n"
    printf "${CYAN}    neusiscode${NC}\n"
    printf "\n${GRAY}  To upgrade later, re-run this installer.${NC}\n"
fi
echo ""
