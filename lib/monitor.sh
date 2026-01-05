#!/bin/bash

# lib/monitor.sh - Temporal Infrastructure Monitoring
# Novelty: Tracks changes over time (Infrastructure Drift)

DATA_STORE_DIR="data/history"

init_monitoring() {
    mkdir -p "$DATA_STORE_DIR"
}

compare_with_history() {
    local target=$1
    local current_results=$2
    local history_file="$DATA_STORE_DIR/${target}_latest.txt"
    local diff_report="$OUTPUT_DIR/${target}_diff_${TIMESTAMP}.txt"
    
    if [[ ! -f "$history_file" ]]; then
        log_info "No history found for $target. Establishing baseline."
        cp "$current_results" "$history_file"
        return
    fi
    
    log_info "Comparing current results with historical baseline..."
    
    # novel: Found Since Last Scan
    comm -13 <(sort "$history_file") <(sort "$current_results") > "$OUTPUT_DIR/new_assets.txt"
    
    # removed: Missing Since Last Scan
    comm -23 <(sort "$history_file") <(sort "$current_results") > "$OUTPUT_DIR/removed_assets.txt"
    
    local new_count=$(wc -l < "$OUTPUT_DIR/new_assets.txt")
    local removed_count=$(wc -l < "$OUTPUT_DIR/removed_assets.txt")
    
    cat <<EOF > "$diff_report"
TEMPORAL ANALYSIS REPORT
========================
Baseline Date: $(stat -c '%y' "$history_file" 2>/dev/null || date)
Current Date: $(date)

[+] NEW ASSETS DETECTED: $new_count
--------------------------------
$(cat "$OUTPUT_DIR/new_assets.txt")

[-] REMOVED ASSETS: $removed_count
--------------------------------
$(cat "$OUTPUT_DIR/removed_assets.txt")
EOF
    
    log_success "Temporal Analysis Complete. New assets: $new_count, Removed: $removed_count"
    cat "$diff_report"
    
    # Update baseline
    cp "$current_results" "$history_file"
}
