#!/bin/bash

# modules/active/reverse_dns.sh - Reverse DNS Lookup
# Resolves discovered subdomains to IPs and performs PTR lookups

run_reverse_dns() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_reverse_dns_${TIMESTAMP}.txt"
    local max_jobs="${MAX_JOBS:-5}"

    log_info "Running reverse DNS lookups for $target..."

    > "$output_file"
    local ip_list=$(mktemp /tmp/serphunter_ips.XXXXXX)
    local ptr_results=$(mktemp /tmp/serphunter_ptr.XXXXXX)

    # Step 1: Resolve the target domain itself
    log_debug "Resolving A records for $target"
    dig +short "$target" A 2>/dev/null >> "$ip_list"

    # Step 2: Also try common subdomains for broader coverage
    for sub in www mail ns1 ns2 ftp; do
        dig +short "${sub}.${target}" A 2>/dev/null >> "$ip_list"
    done

    # Deduplicate IPs
    sort -u "$ip_list" -o "$ip_list"
    # Filter out non-IP lines
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' "$ip_list" > "${ip_list}.clean" 2>/dev/null
    mv "${ip_list}.clean" "$ip_list"

    local ip_count=$(wc -l < "$ip_list")
    if [[ $ip_count -eq 0 ]]; then
        log_warning "No IPs resolved for $target — skipping PTR lookups"
        rm -f "$ip_list" "$ptr_results"
        touch "$output_file"
        return 0
    fi

    log_info "Performing PTR lookups on $ip_count unique IPs..."

    local active_jobs=0

    while IFS= read -r ip; do
        [[ -z "$ip" ]] && continue

        (
            local ptr
            ptr=$(dig +short -x "$ip" +time=3 +tries=1 2>/dev/null | sed 's/\.$//')
            if [[ -n "$ptr" && "$ptr" != *"NXDOMAIN"* ]]; then
                echo "$ip → $ptr" >> "$ptr_results"
                # If the PTR resolves to a hostname under target, add it
                if echo "$ptr" | grep -qi "\.${target}$\|^${target}$"; then
                    echo "$ptr" >> "$output_file"
                fi
            fi
        ) &

        ((active_jobs++)) || true

        if [[ $active_jobs -ge $max_jobs ]]; then
            wait -n 2>/dev/null || wait
            ((active_jobs--)) || true
        fi
    done < "$ip_list"

    wait

    # Deduplicate output
    if [[ -s "$output_file" ]]; then
        sort -u "$output_file" -o "$output_file"
    fi

    # Log PTR results for analysis dir
    if [[ -s "$ptr_results" ]]; then
        local ptr_count=$(wc -l < "$ptr_results")
        local found=$(wc -l < "$output_file")
        # Save full PTR map alongside output
        sort -u "$ptr_results" > "${output_file%.txt}_ptr_map.txt"
        log_success "Reverse DNS: $ptr_count PTR records, $found in-scope hostnames"
    else
        log_info "No PTR records found for $target IPs"
    fi

    rm -f "$ip_list" "$ptr_results"
}
