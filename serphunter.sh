#!/bin/bash

# SerphunterRecon v0.5
# Added HTTP Probing

TARGET=""
OUTPUT_DIR="results"
CONFIG_FILE="config.txt"
PARALLEL_MODE=false
PROBE_HTTP=false
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
    echo -e "${BLUE}SerphunterRecon v0.5${NC}"
    echo "Usage: $0 -d <domain> [-p] [-hp]"
    exit 1
}

load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain) TARGET="$2"; shift 2 ;;
        -p|--parallel) PARALLEL_MODE=true; shift ;;
        -hp|--http-probe) PROBE_HTTP=true; shift ;;
        *) show_help ;;
    esac
done

[[ -z "$TARGET" ]] && show_help

mkdir -p "$OUTPUT_DIR"
load_config

# ... [Enumeration Functions Wrapper same as before] ...
run_crtsh() {
    curl -s "https://crt.sh/?q=%25.$TARGET&output=json" | grep -oP '(?<="common_name":")[^"]*' | sort -u | grep -E "^.*\.$TARGET$|^$TARGET$" > "$OUTPUT_DIR/${TARGET}_crtsh.txt"
}
run_otx() {
    curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$TARGET/passive_dns" | grep -oP '"hostname":"[^"]*' | cut -d'"' -f4 | sort -u > "$OUTPUT_DIR/${TARGET}_otx.txt"
}
run_certspotter() {
    curl -s "https://api.certspotter.com/v1/issuances?domain=$TARGET&include_subdomains=true&expand=dns_names" | grep -oP '(?<="dns_names":\[")[^"]*|"dns_names":\["[^"]*' | grep -v "dns_names" | sort -u > "$OUTPUT_DIR/${TARGET}_certspotter.txt"
}
run_virustotal() {
    [[ -n "$VIRUSTOTAL_API_KEY" ]] && curl -s -H "x-apikey: $VIRUSTOTAL_API_KEY" "https://www.virustotal.com/api/v3/domains/$TARGET/subdomains?limit=40" | grep -oP '(?<="type":"domain","id":")[^"]*' | sort -u > "$OUTPUT_DIR/${TARGET}_virustotal.txt"
}
run_shodan() {
    [[ -n "$SHODAN_API_KEY" ]] && curl -s "https://api.shodan.io/shodan/host/search?query=hostname:$TARGET&key=$SHODAN_API_KEY" | grep -oP '(?<="hostnames":\[")[^"]*|"hostnames":\["[^"]*' | grep -v "hostnames" | sort -u > "$OUTPUT_DIR/${TARGET}_shodan.txt"
}

echo -e "${GREEN}[*] Starting enumeration...${NC}"

if [[ "$PARALLEL_MODE" == true ]]; then
    run_crtsh & run_otx & run_certspotter & run_virustotal & run_shodan &
    wait
else
    run_crtsh; run_otx; run_certspotter; run_virustotal; run_shodan
fi

cat "$OUTPUT_DIR"/${TARGET}_*.txt 2>/dev/null | sort -u > "$OUTPUT_DIR/${TARGET}_all.txt"

# HTTP Probe
if [[ "$PROBE_HTTP" == true ]]; then
    echo -e "${YELLOW}[*] Probing for live servers...${NC}"
    probe_output="$OUTPUT_DIR/${TARGET}_live.txt"
    > "$probe_output"
    while read -r sub; do
        if curl -s -m 5 -o /dev/null -w "%{http_code}" "https://$sub" | grep -q "^[23]"; then
            echo "https://$sub" >> "$probe_output"
            echo -e "${GREEN}[+] Live: https://$sub${NC}"
        elif curl -s -m 5 -o /dev/null -w "%{http_code}" "http://$sub" | grep -q "^[23]"; then
            echo "http://$sub" >> "$probe_output"
            echo -e "${GREEN}[+] Live: http://$sub${NC}"
        fi
    done < "$OUTPUT_DIR/${TARGET}_all.txt"
fi

echo -e "${GREEN}[+] Final results: $OUTPUT_DIR/${TARGET}_all.txt${NC}"
