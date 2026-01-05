#!/bin/bash

# modules/rapiddns.sh - RapidDNS Module

run_rapiddns() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_rapiddns_${TIMESTAMP}.txt"
    
    log_info "Querying RapidDNS for $target..."
    
    # RapidDNS uses a table structure, we need to extract from HTML
    if curl -s "https://rapiddns.io/subdomain/$target?full=1" 2>/dev/null | \
        grep -oP '(?<=<td>)[^<]*' | \
        sort -u | \
        grep -E "^.*\.$target$|^$target$" > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "RapidDNS found $count subdomains"
    else
        log_error "RapidDNS query failed"
        touch "$output_file"
    fi
}
