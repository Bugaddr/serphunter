#!/bin/bash

# lib/network.sh - Network operations and probing

# Probe subdomain for HTTP/HTTPS connectivity
probe_subdomain() {
    local subdomain=$1
    local output_file=$2
    local timeout=${3:-10}
    
    # Try both HTTP and HTTPS
    for protocol in https http; do
        if curl -s -m "$timeout" -o /dev/null -w "%{http_code}" "$protocol://$subdomain" 2>/dev/null | grep -q "^[23][0-9][0-9]$"; then
            echo "$subdomain ($protocol)" >> "$output_file"
            return 0
        fi
    done
    return 1
}

# Probe all discovered subdomains
probe_http_servers() {
    local target=$1
    local combined_file=$2
    local timestamp=$3
    local probe_output="$OUTPUT_DIR/${target}_http_probe_${timestamp}.txt"
    
    echo ""
    log_info "Probing for live HTTP/HTTPS servers..."
    log_info "This may take a while (timeout: ${HTTP_TIMEOUT}s per subdomain)"
    
    > "$probe_output"
    
    local total_found=0
    while IFS= read -r subdomain; do
        [[ -z "$subdomain" ]] && continue
        
        if probe_subdomain "$subdomain" "$probe_output" "$HTTP_TIMEOUT"; then
            ((total_found++))
            echo -ne "\r${GREEN}[+] Live servers found: $total_found${NC}"
        fi
    done < "$combined_file"
    echo ""
    
    log_success "HTTP probe results saved to: $probe_output"
    log_success "Total live servers found: $total_found"
}
