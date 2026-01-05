#!/bin/bash

# modules/active/port_scanner.sh - Lightweight TCP Port Scanner
# Uses bash /dev/tcp for dependency-free port scanning

run_port_scanner() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_portscan_${TIMESTAMP}.txt"
    local max_jobs="${MAX_JOBS:-5}"
    local timeout="${HTTP_TIMEOUT:-3}"

    # Top 20 most common ports
    local ports=(21 22 23 25 53 80 110 143 443 445 993 995 1433 3306 3389 5432 5900 8080 8443 8888)

    log_info "Starting port scan on $target (${#ports[@]} ports)..."

    > "$output_file"

    # Resolve target to check it's reachable
    local target_ip
    target_ip=$(dig +short "$target" A 2>/dev/null | head -1)

    if [[ -z "$target_ip" ]]; then
        log_warning "Could not resolve $target — skipping port scan"
        touch "$output_file"
        return 0
    fi

    log_debug "Resolved $target → $target_ip"

    local open_count=0
    local active_jobs=0

    for port in "${ports[@]}"; do
        (
            if timeout "$timeout" bash -c "echo >/dev/tcp/$target_ip/$port" 2>/dev/null; then
                local service
                case $port in
                    21) service="FTP" ;;
                    22) service="SSH" ;;
                    23) service="Telnet" ;;
                    25) service="SMTP" ;;
                    53) service="DNS" ;;
                    80) service="HTTP" ;;
                    110) service="POP3" ;;
                    143) service="IMAP" ;;
                    443) service="HTTPS" ;;
                    445) service="SMB" ;;
                    993) service="IMAPS" ;;
                    995) service="POP3S" ;;
                    1433) service="MSSQL" ;;
                    3306) service="MySQL" ;;
                    3389) service="RDP" ;;
                    5432) service="PostgreSQL" ;;
                    5900) service="VNC" ;;
                    8080) service="HTTP-Proxy" ;;
                    8443) service="HTTPS-Alt" ;;
                    8888) service="HTTP-Alt" ;;
                    *) service="Unknown" ;;
                esac
                echo "$target:$port ($service) OPEN" >> "$output_file"
            fi
        ) &

        ((active_jobs++)) || true

        if [[ $active_jobs -ge $max_jobs ]]; then
            wait -n 2>/dev/null || wait
            ((active_jobs--)) || true
        fi
    done

    wait

    if [[ -s "$output_file" ]]; then
        sort -t: -k2 -n "$output_file" -o "$output_file"
        open_count=$(wc -l < "$output_file")
        log_success "Port scan found $open_count open ports on $target"
    else
        log_info "No open ports found on $target"
    fi
}
