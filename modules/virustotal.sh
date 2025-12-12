#!/bin/bash

# modules/virustotal.sh - VirusTotal Module

run_virustotal() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_virustotal_${TIMESTAMP}.txt"
    
    if [[ -z "$VIRUSTOTAL_API_KEY" ]]; then
        log_warning "Skipping VirusTotal (No API Key configured)"
        touch "$output_file"
        return
    fi
    
    log_info "Querying VirusTotal for $target..."
    
    if curl -s -H "x-apikey: $VIRUSTOTAL_API_KEY" \
        "https://www.virustotal.com/api/v3/domains/$target/subdomains?limit=40" 2>/dev/null | \
        jq -r '.data[].id' 2>/dev/null | \
        sort -u > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "VirusTotal found $count subdomains"
    else
        log_error "VirusTotal query failed"
        touch "$output_file"
    fi
}
