#!/bin/bash

# SerphunterRecon v0.2
# Added OTX and Certspotter support

TARGET=""
OUTPUT_DIR="results"

# Color codes (discovered these recently!)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

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
    echo -e "${RED}Error: Target domain required.${NC}"
    show_help
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "[*] Starting enumeration for $TARGET..."

# CRT.SH enumeration
enumerate_crtsh() {
    echo "[*] Querying crt.sh..."
    local output_file="$OUTPUT_DIR/${TARGET}_crtsh.txt"
    curl -s "https://crt.sh/?q=%25.$TARGET&output=json" | \
        grep -oP '(?<="common_name":")[^"]*' | \
        sort -u | \
        grep -E "^.*\.$TARGET$|^$TARGET$" > "$output_file"
    echo -e "${GREEN}[+] Saved to $output_file${NC}"
}

# Alienvault OTX
enumerate_otx() {
    echo "[*] Querying Alienvault OTX..."
    local output_file="$OUTPUT_DIR/${TARGET}_otx.txt"
    curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$TARGET/passive_dns" | \
        grep -oP '"hostname":"[^"]*' | \
        cut -d'"' -f4 | \
        sort -u > "$output_file"
    echo -e "${GREEN}[+] Saved to $output_file${NC}"
}

# Certspotter
enumerate_certspotter() {
    echo "[*] Querying Certspotter..."
    local output_file="$OUTPUT_DIR/${TARGET}_certspotter.txt"
    curl -s "https://api.certspotter.com/v1/issuances?domain=$TARGET&include_subdomains=true&expand=dns_names" | \
        grep -oP '(?<="dns_names":\[")[^"]*|"dns_names":\["[^"]*' | \
        grep -v "dns_names" | \
        sort -u > "$output_file"
    echo -e "${GREEN}[+] Saved to $output_file${NC}"
}

enumerate_crtsh
enumerate_otx
enumerate_certspotter

# Combine results
cat "$OUTPUT_DIR"/${TARGET}_*.txt | sort -u > "$OUTPUT_DIR/${TARGET}_all.txt"
echo -e "${GREEN}[+] All unique subdomains saved to $OUTPUT_DIR/${TARGET}_all.txt${NC}"
