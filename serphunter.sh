#!/bin/bash

# SerphunterRecon v0.1
# Basic subdomain enumeration tool

TARGET=""
OUTPUT_FILE=""

show_help() {
    echo "Usage: $0 -d <domain>"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            TARGET="$2"
            shift 2
            ;;
        *)
            show_help
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo "Error: Target domain required."
    show_help
fi

echo "[*] Starting enumeration for $TARGET..."

# CRT.SH enumeration
echo "[*] Querying crt.sh..."
curl -s "https://crt.sh/?q=%25.$TARGET&output=json" | \
    grep -oP '(?<="common_name":")[^"]*' | \
    sort -u | \
    grep -E "^.*\.$TARGET$|^$TARGET$" > "${TARGET}_subdomains.txt"

count=$(wc -l < "${TARGET}_subdomains.txt")
echo "[+] Found $count subdomains."
echo "[+] Results saved to ${TARGET}_subdomains.txt"
