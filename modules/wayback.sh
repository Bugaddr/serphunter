#!/bin/bash

# modules/wayback.sh - Archive.org Wayback Machine

run_wayback() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_wayback_${TIMESTAMP}.txt"
    
    log_info "Querying Wayback Machine for $target..."
    
    if curl -s "http://web.archive.org/cdx/search/cdx?url=*.$target/*&output=json&fl=original&collapse=urlkey" 2>/dev/null | \
        cut -d'/' -f3 | \
        cut -d':' -f1 | \
        sort -u | \
        grep -E "^.*\.$target$|^$target$" > "$output_file"; then
        
        local count=$(wc -l < "$output_file")
        log_success "Wayback Machine found $count subdomains"
    else
        log_error "Wayback Machine query failed"
        touch "$output_file"
    fi
}
