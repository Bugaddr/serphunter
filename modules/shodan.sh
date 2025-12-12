#!/bin/bash

# modules/shodan.sh - Shodan Module

run_shodan() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_shodan_${TIMESTAMP}.txt"
    
    if [[ -z "$SHODAN_API_KEY" ]]; then
        log_warning "Skipping Shodan (No API Key configured)"
        touch "$output_file"
        return
    fi
    
    log_info "Querying Shodan for $target..."
    
    if curl -s "https://api.shodan.io/shodan/host/search?query=hostname:$target&key=$SHODAN_API_KEY" 2>/dev/null | \
        jq -r '.matches[].hostnames[]' 2>/dev/null | \
        sort -u > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "Shodan found $count subdomains"
    else
        log_error "Shodan query failed"
        touch "$output_file"
    fi
}
