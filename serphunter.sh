#!/bin/bash

# SerphunterRecon v0.3
# Added API Support for VirusTotal and Shodan

TARGET=""
OUTPUT_DIR="results"
CONFIG_FILE="config.txt"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# API Keys
VIRUSTOTAL_API_KEY=""
SHODAN_API_KEY=""

show_help() {
    echo "Usage: $0 -d <domain>"
    exit 1
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}[*] Loading configuration from $CONFIG_FILE${NC}"
        source "$CONFIG_FILE"
    else
        echo -e "${YELLOW}[!] Config file not found, creating template...${NC}"
        echo 'VIRUSTOTAL_API_KEY=""' > "$CONFIG_FILE"
        echo 'SHODAN_API_KEY=""' >> "$CONFIG_FILE"
    fi
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

# Initialize
mkdir -p "$OUTPUT_DIR"
load_config
echo -e "${GREEN}[*] Starting enumeration for $TARGET...${NC}"

# Functions
enumerate_crtsh() {
    echo -e "${YELLOW}[*] Querying crt.sh...${NC}"
    curl -s "https://crt.sh/?q=%25.$TARGET&output=json" | \
        grep -oP '(?<="common_name":")[^"]*' | \
        sort -u | \
        grep -E "^.*\.$TARGET$|^$TARGET$" > "$OUTPUT_DIR/${TARGET}_crtsh.txt"
}

enumerate_otx() {
    echo -e "${YELLOW}[*] Querying Alienvault OTX...${NC}"
    curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$TARGET/passive_dns" | \
        grep -oP '"hostname":"[^"]*' | \
        cut -d'"' -f4 | \
        sort -u > "$OUTPUT_DIR/${TARGET}_otx.txt"
}

enumerate_certspotter() {
    echo -e "${YELLOW}[*] Querying Certspotter...${NC}"
    curl -s "https://api.certspotter.com/v1/issuances?domain=$TARGET&include_subdomains=true&expand=dns_names" | \
        grep -oP '(?<="dns_names":\[")[^"]*|"dns_names":\["[^"]*' | \
        grep -v "dns_names" | \
        sort -u > "$OUTPUT_DIR/${TARGET}_certspotter.txt"
}

enumerate_virustotal() {
    if [[ -z "$VIRUSTOTAL_API_KEY" ]]; then
        echo -e "${YELLOW}[!] Skipping VirusTotal (No API Key)${NC}"
        return
    fi
    echo -e "${YELLOW}[*] Querying VirusTotal...${NC}"
    curl -s -H "x-apikey: $VIRUSTOTAL_API_KEY" \
        "https://www.virustotal.com/api/v3/domains/$TARGET/subdomains?limit=40" | \
        grep -oP '(?<="type":"domain","id":")[^"]*' | \
        sort -u > "$OUTPUT_DIR/${TARGET}_virustotal.txt"
}

enumerate_shodan() {
    if [[ -z "$SHODAN_API_KEY" ]]; then
        echo -e "${YELLOW}[!] Skipping Shodan (No API Key)${NC}"
        return
    fi
    echo -e "${YELLOW}[*] Querying Shodan...${NC}"
    curl -s "https://api.shodan.io/shodan/host/search?query=hostname:$TARGET&key=$SHODAN_API_KEY" | \
        grep -oP '(?<="hostnames":\[")[^"]*|"hostnames":\["[^"]*' | \
        grep -v "hostnames" | \
        sort -u > "$OUTPUT_DIR/${TARGET}_shodan.txt"
}

# Run all
enumerate_crtsh
enumerate_otx
enumerate_certspotter
enumerate_virustotal
enumerate_shodan

# Combine
cat "$OUTPUT_DIR"/${TARGET}_*.txt 2>/dev/null | sort -u > "$OUTPUT_DIR/${TARGET}_all.txt"
count=$(wc -l < "$OUTPUT_DIR/${TARGET}_all.txt")
echo -e "${GREEN}[+] Finished! Found $count unique subdomains.${NC}"
