#!/bin/bash

# modules/hackertarget.sh

run_hackertarget() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_hackertarget_${TIMESTAMP}.txt"
    
    log_info "Querying HackerTarget for $target..."
    
    # HackerTarget API returns simple text, no JSON parsing needed usually
    if curl -s "https://api.hackertarget.com/hostsearch/?q=$target" 2>/dev/null | \
        cut -d',' -f1 | \
        sort -u | \
        grep -E "^.*\.$target$|^$target$" > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "HackerTarget found $count subdomains"
    else
        log_error "HackerTarget query failed"
        touch "$output_file"
    fi
}
