#!/bin/bash

# SerphunterRecon - Entry Point
# Author: Security Researcher

# Source core libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/network.sh"
source "$SCRIPT_DIR/lib/report.sh"
source "$SCRIPT_DIR/lib/monitor.sh" # Novelty
source "$SCRIPT_DIR/modules/smart_permute.sh" # Novelty

# Source modules
for module in "$SCRIPT_DIR"/modules/*.sh; do
    source "$module"
done

# Global Variables from core are available

# Help Function (Override)
show_help() {
    print_banner
    echo "Usage: $0 -d <domain> [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --domain      Target domain for enumeration"
    echo "  -p, --parallel    Run enumeration sources in parallel"
    echo "  -hp, --http-probe Probe for live HTTP/HTTPS servers"
    echo "  -h, --help        Show this help message"
    exit 0
}

# Parse Args
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain) TARGET="$2"; shift 2 ;;
        -p|--parallel) PARALLEL_MODE=true; shift ;;
        -hp|--http-probe) PROBE_HTTP=true; shift ;;
        -h|--help) show_help ;;
        *) log_error "Unknown option: $1"; show_help ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    show_help
fi

# Initialization
check_requirements
load_config
mkdir -p "$OUTPUT_DIR"
START_TIME=$(date +%s)

print_banner
log_info "Target: $TARGET"
if [[ "$PARALLEL_MODE" == true ]]; then
    log_info "Mode: Parallel (Max $MAX_JOBS jobs)"
else
    log_info "Mode: Sequential"
fi

# Wildcard Check
detect_wildcard "$TARGET"
WILDCARD_ACTIVE=$?

# Execution
log_info "Starting enumeration..."

if [[ "$PARALLEL_MODE" == true ]]; then
    run_crtsh "$TARGET" &
    run_otx "$TARGET" &
    run_certspotter "$TARGET" &
    run_virustotal "$TARGET" &
    run_shodan "$TARGET" &
    run_hackertarget "$TARGET" &
    run_wayback "$TARGET" &
    run_urlscan "$TARGET" &
    wait
else
    run_crtsh "$TARGET"
    run_otx "$TARGET"
    run_certspotter "$TARGET"
    run_virustotal "$TARGET"
    run_shodan "$TARGET"
    run_hackertarget "$TARGET"
    run_wayback "$TARGET"
    run_urlscan "$TARGET"
fi

# Post-Execution
combined_file="$OUTPUT_DIR/${TARGET}_combined_${TIMESTAMP}.txt"
cat "$OUTPUT_DIR"/${TARGET}_*_${TIMESTAMP}.txt 2>/dev/null | sort -u > "$combined_file"

if [[ "$PROBE_HTTP" == true ]]; then
    probe_http_servers "$TARGET" "$combined_file" "$TIMESTAMP"
fi

# Novelty: Smart Pattern Recognition
if [[ -f "$combined_file" ]]; then
    run_smart_permute "$TARGET" "$combined_file"
fi

# Novelty: Temporal Monitoring
init_monitoring
compare_with_history "$TARGET" "$combined_file"

END_TIME=$(date +%s)
generate_metrics_report "$TARGET" "$TIMESTAMP" "$START_TIME" "$END_TIME" "$combined_file" "$PARALLEL_MODE"

log_success "Enumeration complete!"
