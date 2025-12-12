#!/bin/bash

# modules/crtsh.sh - CRT.SH Enumeration Module

run_crtsh() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_crtsh_${TIMESTAMP}.txt"
    
    log_info "Querying crt.sh for $target..."
    
    if curl -s "https://crt.sh/?q=%25.$target&output=json" 2>/dev/null | \
        jq -r '.[].common_name' 2>/dev/null | \
        sort -u | \
        grep -E "^.*\.$target$|^$target$" > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "CRT.SH found $count subdomains"
    else
        log_error "CRT.SH query failed"
        touch "$output_file"
    fi
}
