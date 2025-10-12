#!/bin/bash

# SerphunterRecon v0.4
# Added Parallel Execution Mode

TARGET=""
OUTPUT_DIR="results"
CONFIG_FILE="config.txt"
PARALLEL_MODE=false
MAX_JOBS=5

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# API Keys
VIRUSTOTAL_API_KEY=""
SHODAN_API_KEY=""

show_help() {
    echo -e "${BLUE}SerphunterRecon v0.4${NC}"
    echo "Usage: $0 -d <domain> [-p|--parallel]"
    exit 1
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            TARGET="$2"
            shift 2
            ;;
        -p|--parallel)
            PARALLEL_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    show_help
fi

mkdir -p "$OUTPUT_DIR"
load_config

echo -e "${GREEN}[*] SerphunterRecon starting for: $TARGET${NC}"
if [[ "$PARALLEL_MODE" == true ]]; then
    echo -e "${GREEN}[*] Parallel mode enabled (Max jobs: $MAX_JOBS)${NC}"
fi

# Tool wrappers
run_crtsh() {
    echo -e "${YELLOW}[*] CRT.SH${NC}"
    curl -s "https://crt.sh/?q=%25.$TARGET&output=json" | \
        grep -oP '(?<="common_name":")[^"]*' | sort -u | grep -E "^.*\.$TARGET$|^$TARGET$" > "$OUTPUT_DIR/${TARGET}_crtsh.txt"
}

run_otx() {
    echo -e "${YELLOW}[*] Alienvault OTX${NC}"
    curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$TARGET/passive_dns" | \
        grep -oP '"hostname":"[^"]*' | cut -d'"' -f4 | sort -u > "$OUTPUT_DIR/${TARGET}_otx.txt"
}

run_certspotter() {
    echo -e "${YELLOW}[*] Certspotter${NC}"
    curl -s "https://api.certspotter.com/v1/issuances?domain=$TARGET&include_subdomains=true&expand=dns_names" | \
        grep -oP '(?<="dns_names":\[")[^"]*|"dns_names":\["[^"]*' | grep -v "dns_names" | sort -u > "$OUTPUT_DIR/${TARGET}_certspotter.txt"
}

run_virustotal() {
    [[ -z "$VIRUSTOTAL_API_KEY" ]] && return
    echo -e "${YELLOW}[*] VirusTotal${NC}"
    curl -s -H "x-apikey: $VIRUSTOTAL_API_KEY" \
        "https://www.virustotal.com/api/v3/domains/$TARGET/subdomains?limit=40" | \
        grep -oP '(?<="type":"domain","id":")[^"]*' | sort -u > "$OUTPUT_DIR/${TARGET}_virustotal.txt"
}

run_shodan() {
    [[ -z "$SHODAN_API_KEY" ]] && return
    echo -e "${YELLOW}[*] Shodan${NC}"
    curl -s "https://api.shodan.io/shodan/host/search?query=hostname:$TARGET&key=$SHODAN_API_KEY" | \
        grep -oP '(?<="hostnames":\[")[^"]*|"hostnames":\["[^"]*' | grep -v "hostnames" | sort -u > "$OUTPUT_DIR/${TARGET}_shodan.txt"
}

# Execution Logic
if [[ "$PARALLEL_MODE" == true ]]; then
    run_crtsh &
    run_otx &
    run_certspotter &
    run_virustotal &
    run_shodan &
    wait
else
    run_crtsh
    run_otx
    run_certspotter
    run_virustotal
    run_shodan
fi

# Combine
cat "$OUTPUT_DIR"/${TARGET}_*.txt 2>/dev/null | sort -u > "$OUTPUT_DIR/${TARGET}_all.txt"
echo -e "${GREEN}[+] Done! Results combined in $OUTPUT_DIR/${TARGET}_all.txt${NC}"
