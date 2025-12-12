#!/bin/bash

# modules/otx.sh - Alienvault OTX Module

run_otx() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_otx_${TIMESTAMP}.txt"
    
    log_info "Querying Alienvault OTX for $target..."
    
    if curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$target/passive_dns" 2>/dev/null | \
        jq -r '.passive_dns[].hostname' 2>/dev/null | \
        sort -u > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "Alienvault OTX found $count subdomains"
    else
        log_error "Alienvault OTX query failed"
        touch "$output_file"
    fi
}
