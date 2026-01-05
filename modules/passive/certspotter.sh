#!/bin/bash

# modules/certspotter.sh - Certspotter Module

run_certspotter() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_certspotter_${TIMESTAMP}.txt"
    
    log_info "Querying Certspotter for $target..."
    
    if curl -s "https://api.certspotter.com/v1/issuances?domain=$target&include_subdomains=true&expand=dns_names" 2>/dev/null | \
        jq -r '.[].dns_names[]' 2>/dev/null | \
        sort -u > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "Certspotter found $count subdomains"
    else
        log_error "Certspotter query failed"
        touch "$output_file"
    fi
}
