#!/bin/bash

# lib/report.sh - Metrics and Reporting

generate_metrics_report() {
    local target=$1
    local timestamp=$2
    local start_time=$3
    local end_time=$4
    local combined_file=$5
    local parallel_mode=$6
    
    local metrics_file="$OUTPUT_DIR/${target}_metrics_${timestamp}.txt"
    local duration=$((end_time - start_time))
    
    log_info "Generating comprehensive metrics report..."
    
    # Count unique subdomains
    local total_unique=$(cat "$combined_file" 2>/dev/null | wc -l)
    
    # Locate source files (check sources/ subdir first, then OUTPUT_DIR)
    local sources_dir="${BASE_OUTPUT_DIR:-$OUTPUT_DIR}/${target}/sources"
    [[ ! -d "$sources_dir" ]] && sources_dir="$OUTPUT_DIR"
    
    # Gather source stats
    local stats_block=""
    for file in "$sources_dir"/${target}_*_${timestamp}.txt; do
        if [[ "$file" != *"$combined_file"* && "$file" != *metrics* && "$file" != *probe* ]]; then
            local source_name=$(basename "$file" | sed "s/^${target}_//; s/_${timestamp}.txt//")
            local count=$(cat "$file" 2>/dev/null | wc -l)
            stats_block+="${source_name^^}: $count subdomains\n"
        fi
    done
    
    # Generate report content
    cat <<EOF > "$metrics_file"
╔═══════════════════════════════════════════════════════╗
║          SerphunterRecon - Execution Report           ║
╚═══════════════════════════════════════════════════════╝

TARGET: $target
TIMESTAMP: $timestamp
EXECUTION TIME: ${duration}s
MODE: $([ "$parallel_mode" = true ] && echo "Parallel" || echo "Sequential")

═══════════════════════════════════════════════════════
ENUMERATION RESULTS BY SOURCE
═══════════════════════════════════════════════════════
$(echo -e "$stats_block")

═══════════════════════════════════════════════════════
SUMMARY STATISTICS
═══════════════════════════════════════════════════════
Total Unique Subdomains: $total_unique
Execution Time: ${duration} seconds

═══════════════════════════════════════════════════════
RECOMMENDATIONS
═══════════════════════════════════════════════════════
$(recommendation_logic "$total_unique")

EOF
    
    # Append probe results if available
    local probe_file="$OUTPUT_DIR/${target}_http_probe_${timestamp}.txt"
    if [[ -f "$probe_file" ]]; then
        local live_count=$(wc -l < "$probe_file")
        cat <<EOF >> "$metrics_file"
═══════════════════════════════════════════════════════
HTTP PROBE RESULTS
═══════════════════════════════════════════════════════
Live Servers Found: $live_count
See full list in: $(basename "$probe_file")

EOF
    fi

    log_success "Detailed report saved to: $metrics_file"
    cat "$metrics_file"
    
    # Generate JSON Report for Interoperability
    local json_file="$OUTPUT_DIR/${target}_report_${timestamp}.json"
    
    # Create JSON structure using jq
    jq -n \
        --arg target "$target" \
        --arg timestamp "$timestamp" \
        --arg execution_time "$duration" \
        --arg unique_count "$total_unique" \
        --arg mode "$([ "$parallel_mode" = true ] && echo "Parallel" || echo "Sequential")" \
        '{
            meta: {
                tool: "SerphunterRecon",
                version: "2.0",
                timestamp: $timestamp,
                execution_time_seconds: $execution_time,
                mode: $mode
            },
            target: {
                domain: $target,
                total_subdomains: $unique_count
            },
            results: []
        }' > "$json_file"
        
    log_success "JSON report saved to: $json_file"
}

recommendation_logic() {
    local count=$1
    if [[ $count -lt 10 ]]; then
        echo "⚠ Low number of subdomains found. Consider running manual recon or adding more API keys."
    elif [[ $count -lt 50 ]]; then
        echo "✓ Moderate attack surface. Recommended: Full port scan on discovered hosts."
    else
        echo "✓ Large attack surface ($count+ hosts). Recommended: Automated vulnerability scanning."
    fi
}
