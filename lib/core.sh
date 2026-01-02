#!/bin/bash

# lib/core.sh - Core functions, logging, and UI

# ── Runtime Flags ──
export VERBOSE_MODE=false
export QUIET_MODE=false
export NO_COLOR=false
export DRY_RUN=false
export NO_CACHE=false

# ── Color codes ──
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export DIM='\033[2m'
export NC='\033[0m' # No Color

# ── Global Configuration ──
export CONFIG_FILE="config/serphunter.conf"
export OUTPUT_DIR="results"
export MAX_JOBS=5
export HTTP_TIMEOUT=10

# ── Plugin Filtering ──
export EXCLUDE_PLUGINS=""
export ONLY_PLUGINS=""

# ── API Keys ──
export VIRUSTOTAL_API_KEY=""
export SHODAN_API_KEY=""
export CENSYS_API_ID=""
export CENSYS_API_SECRET=""

# Apply --no-color: strip all color codes
_apply_no_color() {
    if [[ "$NO_COLOR" == true ]]; then
        RED="" GREEN="" YELLOW="" BLUE="" CYAN="" BOLD="" DIM="" NC=""
    fi
}

print_banner() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          SerphunterRecon - Enterprise Edition         ║${NC}"
    echo -e "${BLUE}║          v1.5 - Professional Security Tool            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_info() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    [[ "$QUIET_MODE" == true ]] && return
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    [[ "$VERBOSE_MODE" != true ]] && return
    echo -e "${DIM}${CYAN}[DEBUG]${NC} $1"
}

check_requirements() {
    local required_tools=("curl" "grep" "sort" "uniq" "jq")

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool not found: $tool"
            echo "Please run ./setup/install.sh first."
            exit 1
        fi
    done
    log_debug "All required tools found: ${required_tools[*]}"
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        log_warning "Config file not found at $CONFIG_FILE"
    fi
}
