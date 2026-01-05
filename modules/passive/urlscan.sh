#!/bin/bash

# modules/urlscan.sh - URLScan.io Module

run_urlscan() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_urlscan_${TIMESTAMP}.txt"
    
    log_info "Querying URLScan.io for $target..."
    
    if curl -s "https://urlscan.io/api/v1/search/?q=domain:$target" 2>/dev/null | \
        jq -r '.results[].page.domain' 2>/dev/null | \
        sort -u | \
        grep -E "^.*\.$target$|^$target$" > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "URLScan.io found $count subdomains"
    else
        log_error "URLScan.io query failed"
        touch "$output_file"
    fi
}
