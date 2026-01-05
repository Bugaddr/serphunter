#!/bin/bash

# modules/subdomaincenter.sh - Subdomain.center Module

run_subdomaincenter() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_subdomaincenter_${TIMESTAMP}.txt"
    
    log_info "Querying Subdomain.center for $target..."
    
    if curl -s "https://api.subdomain.center/?domain=$target" 2>/dev/null | \
        jq -r '.[]' 2>/dev/null | \
        sort -u | \
        grep -E "^.*\.$target$|^$target$" > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "Subdomain.center found $count subdomains"
    else
        log_error "Subdomain.center query failed"
        touch "$output_file"
    fi
}
