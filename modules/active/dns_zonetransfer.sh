#!/bin/bash

# modules/active/dns_zonetransfer.sh - DNS Zone Transfer (AXFR) Attempt
# Queries authoritative nameservers and attempts zone transfers

run_dns_zonetransfer() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_dns_zonetransfer_${TIMESTAMP}.txt"

    log_info "Attempting DNS zone transfer on $target..."

    > "$output_file"

    # Get authoritative nameservers
    local nameservers
    nameservers=$(dig +short NS "$target" 2>/dev/null | sed 's/\.$//')

    if [[ -z "$nameservers" ]]; then
        log_warning "No nameservers found for $target"
        touch "$output_file"
        return 0
    fi

    log_debug "Nameservers for $target: $(echo $nameservers | tr '\n' ' ')"

    local transfer_success=false

    while IFS= read -r ns; do
        [[ -z "$ns" ]] && continue

        log_debug "Trying AXFR against $ns..."

        local axfr_result
        axfr_result=$(dig @"$ns" "$target" AXFR +time=10 +tries=1 2>/dev/null)

        if echo "$axfr_result" | grep -q "Transfer failed\|; Transfer failed\|connection timed out"; then
            log_debug "Zone transfer denied by $ns"
            continue
        fi

        # Extract hostnames from successful transfer
        local hosts
        hosts=$(echo "$axfr_result" | grep -E "^[a-zA-Z0-9]" | awk '{print $1}' | sed 's/\.$//' | sort -u)

        if [[ -n "$hosts" ]]; then
            transfer_success=true
            log_warning "Zone transfer SUCCESSFUL from $ns — this is a security vulnerability!"
            echo "$hosts" >> "$output_file"
        fi
    done <<< "$nameservers"

    # Deduplicate
    if [[ -s "$output_file" ]]; then
        sort -u "$output_file" -o "$output_file"
        local count=$(wc -l < "$output_file")
        log_success "Zone transfer yielded $count records from $target"
    else
        log_info "Zone transfer not permitted on $target (expected for secure configs)"
    fi
}
