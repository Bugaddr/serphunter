#!/bin/bash

# SerphunterRecon v2.0 - Intelligent Attack Surface Analysis Framework
# Entry Point / Execution Controller

set -euo pipefail

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source core libraries
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/network.sh"
source "$SCRIPT_DIR/lib/report.sh"
source "$SCRIPT_DIR/lib/monitor.sh"
source "$SCRIPT_DIR/lib/ratelimit.sh"
source "$SCRIPT_DIR/lib/plugin.sh"
source "$SCRIPT_DIR/lib/scope.sh"
source "$SCRIPT_DIR/lib/cache.sh"
source "$SCRIPT_DIR/lib/notify.sh"
source "$SCRIPT_DIR/lib/html_report.sh"
source "$SCRIPT_DIR/lib/fingerprint.sh"
source "$SCRIPT_DIR/lib/risk.sh"
source "$SCRIPT_DIR/lib/markov.sh"
source "$SCRIPT_DIR/lib/logger.sh"

# Defaults
TARGET=""
TARGET_FILE=""
PARALLEL_MODE=false
PROBE_HTTP=false
SCOPE_FILE=""
GENERATE_HTML=false
RUN_TAKEOVER=false
RUN_FINGERPRINT=false
RUN_RISK=false
RUN_MARKOV=false
RUN_ALL_ADVANCED=false
export TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Help
show_help() {
    print_banner
    echo "Usage: $0 -d <domain> [OPTIONS]"
    echo ""
    echo "Target Options:"
    echo "  -d, --domain       Single target domain"
    echo "  -dL, --domain-list File containing list of domains (one per line)"
    echo ""
    echo "Recon Mode:"
    echo "  --passive          Run passive recon only (default, API queries)"
    echo "  --active           Run active recon only (DNS brute-force, port scan)"
    echo "  --recon <mode>     Set recon mode: passive, active, or all"
    echo "  -w, --wordlist     Custom wordlist for DNS brute-force"
    echo ""
    echo "Execution Options:"
    echo "  -p, --parallel     Run enumeration sources in parallel"
    echo "  -hp, --http-probe  Probe for live HTTP/HTTPS servers"
    echo "  --html             Generate styled HTML report"
    echo "  -j, --jobs <n>     Max parallel jobs (default: 5)"
    echo "  -t, --timeout <s>  HTTP timeout per request in seconds (default: 10)"
    echo "  --rate <n>         Max requests per rate-limit window (default: 5)"
    echo "  --dry-run          Show what would run without executing"
    echo ""
    echo "Analysis Options:"
    echo "  --takeover         Check for subdomain takeover vulnerabilities"
    echo "  --fingerprint      Run technology fingerprinting"
    echo "  --risk             Run risk scoring engine"
    echo "  --markov           Run Markov chain prediction"
    echo "  --full             Enable all advanced analysis"
    echo ""
    echo "Output Options:"
    echo "  -o, --output <dir> Custom output directory (default: results/)"
    echo "  -v, --verbose      Enable debug-level output"
    echo "  -q, --quiet        Suppress all output except errors"
    echo "  --no-color         Disable colored output"
    echo "  --no-cache         Disable result caching"
    echo ""
    echo "Plugin Options:"
    echo "  --exclude <list>   Comma-separated plugins to skip"
    echo "  --only <list>      Comma-separated plugins to run exclusively"
    echo "  --list-plugins     Show all installed plugins"
    echo ""
    echo "Filtering Options:"
    echo "  -s, --scope        Path to scope file (INI format)"
    echo ""
    echo "Information:"
    echo "  -h, --help         Show this help message"
    echo "  -V, --version      Show version information"
    exit 0
}

show_version() {
    echo "SerphunterRecon v2.0"
    local passive_count=$(ls "$SCRIPT_DIR/modules/passive/"*.sh 2>/dev/null | wc -l)
    local active_count=$(ls "$SCRIPT_DIR/modules/active/"*.sh 2>/dev/null | wc -l)
    echo "Modules: $passive_count passive, $active_count active"
    exit 0
}

# Parse Arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            TARGET="$2"; shift 2 ;;
        -dL|--domain-list)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            TARGET_FILE="$2"; shift 2 ;;
        -p|--parallel)     PARALLEL_MODE=true; shift ;;
        -hp|--http-probe)  PROBE_HTTP=true; shift ;;
        -s|--scope)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            SCOPE_FILE="$2"; shift 2 ;;
        -o|--output)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            OUTPUT_DIR="$2"; shift 2 ;;
        -t|--timeout)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            HTTP_TIMEOUT="$2"; shift 2 ;;
        -j|--jobs)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            MAX_JOBS="$2"; shift 2 ;;
        --rate)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            DEFAULT_RATE="$2"; shift 2 ;;
        --exclude)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            EXCLUDE_PLUGINS="$2"; shift 2 ;;
        --only)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            ONLY_PLUGINS="$2"; shift 2 ;;
        --html)            GENERATE_HTML=true; shift ;;
        --takeover)        RUN_TAKEOVER=true; shift ;;
        --fingerprint)     RUN_FINGERPRINT=true; shift ;;
        --risk)            RUN_RISK=true; shift ;;
        --markov)          RUN_MARKOV=true; shift ;;
        --full)            RUN_ALL_ADVANCED=true; shift ;;
        --passive)         RECON_MODE="passive"; shift ;;
        --active)          RECON_MODE="active"; shift ;;
        --recon)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            RECON_MODE="$2"; shift 2 ;;
        -w|--wordlist)
            [[ $# -lt 2 ]] && { log_error "Option $1 requires an argument"; show_help; }
            WORDLIST="$2"; shift 2 ;;
        -v|--verbose)      VERBOSE_MODE=true; shift ;;
        -q|--quiet)        QUIET_MODE=true; shift ;;
        --no-color)        NO_COLOR=true; _apply_no_color; shift ;;
        --no-cache)        NO_CACHE=true; shift ;;
        --dry-run)         DRY_RUN=true; shift ;;
        --list-plugins)    init_plugin_system; list_plugins; exit 0 ;;
        -V|--version)      show_version ;;
        -h|--help)         show_help ;;
        *)                 log_error "Unknown option: $1"; show_help ;;
    esac
done

# Validate input
if [[ -z "$TARGET" && -z "$TARGET_FILE" ]]; then
    show_help
fi

# Validate domain list file exists
if [[ -n "$TARGET_FILE" && ! -f "$TARGET_FILE" ]]; then
    log_error "Domain list file not found: $TARGET_FILE"
    exit 1
fi

# ──────────────────────────────────────────────
# Core scan function for a single domain
# ──────────────────────────────────────────────
scan_domain() {
    local domain=$1
    
    # ── Create per-domain output structure ──
    local DOMAIN_DIR="${BASE_OUTPUT_DIR}/${domain}"
    local SOURCES_DIR="${DOMAIN_DIR}/sources"
    local REPORTS_DIR="${DOMAIN_DIR}/reports"
    local ANALYSIS_DIR="${DOMAIN_DIR}/analysis"
    
    mkdir -p "$SOURCES_DIR" "$REPORTS_DIR" "$ANALYSIS_DIR"
    
    log_debug "Output structure: $DOMAIN_DIR/{sources,reports,analysis}"
    
    log_info "═══════════════════════════════════════"
    log_info "Scanning: $domain"
    log_info "═══════════════════════════════════════"
    
    local domain_start=$(date +%s)
    
    # ── Phase 1: Enumeration (output to sources/) ──
    OUTPUT_DIR="$SOURCES_DIR"
    execute_plugins "$domain" "$PARALLEL_MODE"
    
    # ── Phase 2: Combine results ──
    OUTPUT_DIR="$ANALYSIS_DIR"
    local combined_file="$ANALYSIS_DIR/${domain}_combined_${TIMESTAMP}.txt"
    cat "$SOURCES_DIR"/${domain}_*_${TIMESTAMP}.txt 2>/dev/null | sort -u > "$combined_file"

    # Apply scope filter if configured
    if [[ -n "$SCOPE_FILE" ]]; then
        local filtered_file="$ANALYSIS_DIR/${domain}_scoped_${TIMESTAMP}.txt"
        apply_scope_filter "$combined_file" "$filtered_file"
        combined_file="$filtered_file"
    fi

    # Smart Pattern Recognition
    if [[ -f "$combined_file" ]]; then
        run_smart_permute "$domain" "$combined_file"
    fi

    # ── Phase 3: Advanced Analysis Pipeline ──
    
    # Markov Chain Prediction
    if [[ "$RUN_MARKOV" == true || "$RUN_ALL_ADVANCED" == true ]]; then
        run_markov_prediction "$domain" "$combined_file" 50
    fi
    
    # Subdomain Takeover Detection
    if [[ "$RUN_TAKEOVER" == true || "$RUN_ALL_ADVANCED" == true ]]; then
        run_takeover "$domain" "$combined_file"
    fi
    
    # Technology Fingerprinting
    if [[ "$RUN_FINGERPRINT" == true || "$RUN_ALL_ADVANCED" == true ]]; then
        run_fingerprint "$domain" "$combined_file"
    fi
    
    # Risk Scoring
    if [[ "$RUN_RISK" == true || "$RUN_ALL_ADVANCED" == true ]]; then
        run_risk_assessment "$domain" "$combined_file"
    fi

    # HTTP Probing
    if [[ "$PROBE_HTTP" == true ]]; then
        probe_http_servers "$domain" "$combined_file" "$TIMESTAMP"
    fi

    # Temporal Monitoring
    compare_with_history "$domain" "$combined_file"

    # Calculate duration
    local domain_end=$(date +%s)
    local duration=$((domain_end - domain_start))

    # ── Phase 4: Reports (output to reports/) ──
    OUTPUT_DIR="$REPORTS_DIR"
    generate_metrics_report "$domain" "$TIMESTAMP" "$domain_start" "$domain_end" "$combined_file" "$PARALLEL_MODE"

    if [[ "$GENERATE_HTML" == true ]]; then
        generate_html_report "$domain" "$TIMESTAMP" "$combined_file" "$duration"
    fi

    # Send notifications
    local total=$(wc -l < "$combined_file")
    notify_all "$domain" "$total" "0" "$duration"
    
    log_success "Scan complete for $domain ($total subdomains in ${duration}s)"
    log_info "Results saved to: $DOMAIN_DIR/"
}

# ──────────────────────────────────────────────
# Main Execution
# ──────────────────────────────────────────────
main() {
    print_banner
    
    # Set base output directory (preserved across scan_domain calls)
    BASE_OUTPUT_DIR="$OUTPUT_DIR"
    local LOGS_DIR="${BASE_OUTPUT_DIR}/logs"
    
    # Verbose: show configuration
    log_debug "Configuration:"
    log_debug "  Target: ${TARGET:-none}"
    log_debug "  Target File: ${TARGET_FILE:-none}"
    log_debug "  Output Dir: $BASE_OUTPUT_DIR"
    log_debug "  Parallel: $PARALLEL_MODE"
    log_debug "  HTTP Timeout: ${HTTP_TIMEOUT}s"
    log_debug "  Max Jobs: $MAX_JOBS"
    log_debug "  Verbose: $VERBOSE_MODE"
    log_debug "  Quiet: $QUIET_MODE"
    log_debug "  No Color: $NO_COLOR"
    log_debug "  No Cache: $NO_CACHE"
    log_debug "  Dry Run: $DRY_RUN"
    log_debug "  Recon Mode: $RECON_MODE"
    log_debug "  Wordlist: ${WORDLIST:-default}"
    log_debug "  Exclude Plugins: ${EXCLUDE_PLUGINS:-none}"
    log_debug "  Only Plugins: ${ONLY_PLUGINS:-none}"
    
    # Initialize subsystems
    check_requirements
    load_config
    mkdir -p "$BASE_OUTPUT_DIR" "$LOGS_DIR"
    init_logger "$LOGS_DIR"
    init_rate_limiter
    init_plugin_system
    
    if [[ "$NO_CACHE" != true ]]; then
        init_cache
    else
        log_debug "Cache disabled via --no-cache"
    fi
    
    init_monitoring
    load_notification_config
    
    # Enable all advanced if --full is set
    if [[ "$RUN_ALL_ADVANCED" == true ]]; then
        RUN_TAKEOVER=true
        RUN_FINGERPRINT=true
        RUN_RISK=true
        RUN_MARKOV=true
        GENERATE_HTML=true
    fi
    
    # Load scope if provided
    [[ -n "$SCOPE_FILE" ]] && load_scope "$SCOPE_FILE"
    
    # Wildcard check
    if [[ -n "$TARGET" ]]; then
        detect_wildcard "$TARGET" || true
    fi
    
    log_info "Mode: $([ "$PARALLEL_MODE" = true ] && echo "Parallel" || echo "Sequential")"
    
    # Execute scans
    if [[ -n "$TARGET" ]]; then
        # Single target mode
        scan_domain "$TARGET"
    fi
    
    if [[ -n "$TARGET_FILE" ]]; then
        # Multi-target mode
        local domain_count=$(wc -l < "$TARGET_FILE")
        log_info "Multi-target mode: $domain_count domains from $TARGET_FILE"
        
        while IFS= read -r domain; do
            [[ -z "$domain" || "$domain" == \#* ]] && continue
            scan_domain "$domain"
        done < "$TARGET_FILE"
    fi
    
    # Cleanup
    cleanup_rate_limiter
    cache_gc
    rotate_logs
    
    log_success "All scans complete!"
}

main
