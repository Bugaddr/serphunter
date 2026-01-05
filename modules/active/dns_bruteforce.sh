#!/bin/bash

# modules/active/dns_bruteforce.sh - DNS Brute-Force Subdomain Discovery
# Resolves candidate subdomains from a wordlist using dig

run_dns_bruteforce() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_dns_bruteforce_${TIMESTAMP}.txt"
    local wordlist="${WORDLIST:-$SCRIPT_DIR/data/wordlists/subdomains.txt}"
    local max_jobs="${MAX_JOBS:-5}"

    log_info "Starting DNS brute-force against $target..."

    if [[ ! -f "$wordlist" ]]; then
        log_error "Wordlist not found: $wordlist"
        touch "$output_file"
        return 1
    fi

    local total_words=$(wc -l < "$wordlist")
    log_info "Wordlist: $(basename "$wordlist") ($total_words entries)"

    > "$output_file"
    local found=0
    local checked=0
    local active_jobs=0

    while IFS= read -r word || [[ -n "$word" ]]; do
        [[ -z "$word" || "$word" == \#* ]] && continue

        local fqdn="${word}.${target}"

        (
            local result
            result=$(dig +short +time=3 +tries=1 "$fqdn" A 2>/dev/null)
            if [[ -n "$result" && "$result" != *"NXDOMAIN"* && "$result" != *"SERVFAIL"* ]]; then
                echo "$fqdn" >> "$output_file"
            fi
        ) &

        ((active_jobs++)) || true
        ((checked++)) || true

        # Throttle parallel jobs
        if [[ $active_jobs -ge $max_jobs ]]; then
            wait -n 2>/dev/null || wait
            ((active_jobs--)) || true
        fi

        # Progress indicator every 100 words
        if [[ $((checked % 100)) -eq 0 ]]; then
            log_debug "DNS brute-force progress: $checked/$total_words checked"
        fi
    done < "$wordlist"

    wait

    # Deduplicate
    if [[ -s "$output_file" ]]; then
        sort -u "$output_file" -o "$output_file"
        found=$(wc -l < "$output_file")
    fi

    log_success "DNS brute-force found $found subdomains for $target"
}
