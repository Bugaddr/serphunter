#!/bin/bash

###############################################################################
# SerphunterRecon v1.0 - Production Release
# Author: Security Researcher
# Date: December 2025
# Description: Professional-grade subdomain enumeration and reconnaissance tool
#
# Features:
#   - Multi-source passive subdomain enumeration (7+ sources)
#   - Parallel execution for faster results
#   - HTTP/HTTPS probing for live server detection
#   - Comprehensive metrics and detailed reporting
#   - API key support for extended coverage
#   - Organized output with per-source results
#   - Advanced deduplication and analysis
#
# Usage:
#   ./serphunter.sh -d example.com                    # Basic enumeration
#   ./serphunter.sh -d example.com --parallel         # Faster parallel mode
#   ./serphunter.sh -d example.com --http-probe       # With live server detection
#
###############################################################################

set -e

# Color codes for output
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
NC='\033[0m' # No Color

# Global variables
TARGET=""
OUTPUT_DIR="results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PARALLEL_MODE=false
MAX_JOBS=5
PROBE_HTTP=false
HTTP_TIMEOUT=10
START_TIME=""
END_TIME=""
ENABLE_METRICS=true

# API Keys (loaded from config)
VIRUSTOTAL_API_KEY=""
SHODAN_API_KEY=""
CENSYS_API_ID=""
CENSYS_API_SECRET=""

# Display help
show_help() {
    echo -e "${BLUE}SerphunterRecon v1.0${NC}"
    echo "Usage: $0 -d <domain> [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --domain      Target domain for enumeration"
    echo "  -p, --parallel    Run enumeration sources in parallel"
    echo "  -hp, --http-probe Probe for live HTTP/HTTPS servers"
    echo "  -h, --help        Show this help message"
    echo "  -v, --version     Show version information"
    exit 0
}

# Display version
show_version() {
    echo "SerphunterRecon v1.0 - Production Release"
    echo "Released: December 2025"
    echo ""
    echo "Features:"
    echo "  ✓ Multi-source passive enumeration (7+ sources)"
    echo "  ✓ Parallel execution for fast results"
    echo "  ✓ HTTP/HTTPS live server probing"
    echo "  ✓ Comprehensive metrics and reporting"
    echo "  ✓ API key support (VirusTotal, Shodan, etc.)"
    echo "  ✓ Advanced result deduplication"
    echo "  ✓ Professional-grade output formatting"
    echo ""
    exit 0
}

# Parse command line arguments
parse_arguments() {
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
            -hp|--http-probe)
                PROBE_HTTP=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            -v|--version)
                show_version
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                ;;
        esac
    done
}

# Initialize directories
init_directories() {
    mkdir -p "$OUTPUT_DIR"
}

# Check for required tools
check_requirements() {
    local required_tools=("curl" "grep" "sort" "uniq")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}Error: $tool is not installed${NC}"
            exit 1
        fi
    done
}

# Load configuration from config file
load_config() {
    local config_file="${1:-config.txt}"
    
    if [[ -f "$config_file" ]]; then
        # Source the config file (safely)
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue
            
            # Trim whitespace and quotes
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs | tr -d '"')
            
            case "$key" in
                VIRUSTOTAL_API_KEY) VIRUSTOTAL_API_KEY="$value" ;;
                SHODAN_API_KEY) SHODAN_API_KEY="$value" ;;
                CENSYS_API_ID) CENSYS_API_ID="$value" ;;
                CENSYS_API_SECRET) CENSYS_API_SECRET="$value" ;;
            esac
        done < "$config_file"
    fi
}

# Basic subdomain enumeration using crt.sh
enumerate_crtsh() {
    local domain=$1
    local output_file="$OUTPUT_DIR/${domain}_crtsh_${TIMESTAMP}.txt"
    
    echo -e "${YELLOW}[*] Querying crt.sh for $domain${NC}"
    
    curl -s "https://crt.sh/?q=%25.$domain&output=json" 2>/dev/null | \
        grep -oP '(?<="common_name":")[^"]*' | \
        sort -u | \
        grep -E "^.*\.$domain$|^$domain$" > "$output_file" 2>/dev/null || true
    
    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
    cat "$output_file" | wc -l | xargs echo "[+] Found subdomains:"
}

# Query alienvault OTX
enumerate_otx() {
    local domain=$1
    local output_file="$OUTPUT_DIR/${domain}_otx_${TIMESTAMP}.txt"
    
    echo -e "${YELLOW}[*] Querying Alienvault OTX for $domain${NC}"
    
    curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$domain/passive_dns" 2>/dev/null | \
        grep -oP '"hostname":"[^"]*' | \
        cut -d'"' -f4 | \
        sort -u > "$output_file" 2>/dev/null || true
    
    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
    cat "$output_file" | wc -l | xargs echo "[+] Found subdomains:"
}

# Query Certspotter API
enumerate_certspotter() {
    local domain=$1
    local output_file="$OUTPUT_DIR/${domain}_certspotter_${TIMESTAMP}.txt"
    
    echo -e "${YELLOW}[*] Querying Certspotter for $domain${NC}"
    
    curl -s "https://api.certspotter.com/v1/issuances?domain=$domain&include_subdomains=true&expand=dns_names" 2>/dev/null | \
        grep -oP '(?<="dns_names":\[")[^"]*|"dns_names":\["[^"]*' | \
        grep -v "dns_names" | \
        sort -u > "$output_file" 2>/dev/null || true
    
    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
    cat "$output_file" 2>/dev/null | wc -l | xargs echo "[+] Found subdomains:"
}

# Query using JLDC Anubis API
enumerate_anubis() {
    local domain=$1
    local output_file="$OUTPUT_DIR/${domain}_anubis_${TIMESTAMP}.txt"
    
    echo -e "${YELLOW}[*] Querying JLDC Anubis for $domain${NC}"
    
    curl -s "https://jldc.me/anubis/subdomains/$domain" 2>/dev/null | \
        grep -oP '"[^"]*\.$domain"' | \
        tr -d '"' | \
        sort -u > "$output_file" 2>/dev/null || true
    
    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
    cat "$output_file" 2>/dev/null | wc -l | xargs echo "[+] Found subdomains:"
}

# Query using Subdomain Center
enumerate_subdomain_center() {
    local domain=$1
    local output_file="$OUTPUT_DIR/${domain}_subdomaincenter_${TIMESTAMP}.txt"
    
    echo -e "${YELLOW}[*] Querying Subdomain.center for $domain${NC}"
    
    curl -s "https://api.subdomain.center/?domain=$domain" 2>/dev/null | \
        grep -oP '(?<="subdomain":")[^"]*' | \
        sort -u > "$output_file" 2>/dev/null || true
    
    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
    cat "$output_file" 2>/dev/null | wc -l | xargs echo "[+] Found subdomains:"
}

# Query VirusTotal API
enumerate_virustotal() {
    local domain=$1
    local output_file="$OUTPUT_DIR/${domain}_virustotal_${TIMESTAMP}.txt"
    
    if [[ -z "$VIRUSTOTAL_API_KEY" ]]; then
        echo -e "${YELLOW}[!] Skipping VirusTotal (API key not configured)${NC}"
        touch "$output_file"
        return
    fi
    
    echo -e "${YELLOW}[*] Querying VirusTotal for $domain${NC}"
    
    curl -s -H "x-apikey: $VIRUSTOTAL_API_KEY" \
        "https://www.virustotal.com/api/v3/domains/$domain/subdomains?limit=40" 2>/dev/null | \
        grep -oP '(?<="type":"domain","id":")[^"]*' | \
        sort -u > "$output_file" 2>/dev/null || true
    
    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
    cat "$output_file" 2>/dev/null | wc -l | xargs echo "[+] Found subdomains:"
}

# Query Shodan API
enumerate_shodan() {
    local domain=$1
    local output_file="$OUTPUT_DIR/${domain}_shodan_${TIMESTAMP}.txt"
    
    if [[ -z "$SHODAN_API_KEY" ]]; then
        echo -e "${YELLOW}[!] Skipping Shodan (API key not configured)${NC}"
        touch "$output_file"
        return
    fi
    
    echo -e "${YELLOW}[*] Querying Shodan for $domain${NC}"
    
    curl -s "https://api.shodan.io/shodan/host/search?query=hostname:$domain&key=$SHODAN_API_KEY" 2>/dev/null | \
        grep -oP '(?<="hostnames":\[")[^"]*|"hostnames":\["[^"]*' | \
        grep -v "hostnames" | \
        sort -u > "$output_file" 2>/dev/null || true
    
    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
    cat "$output_file" 2>/dev/null | wc -l | xargs echo "[+] Found subdomains:"
}

# Execute enumeration with job control
run_enumeration() {
    local domain=$1
    local tool_name=$2
    local output_file="$OUTPUT_DIR/${domain}_${tool_name}_${TIMESTAMP}.txt"
    
    echo -e "${YELLOW}[*] Running $tool_name enumeration${NC}"
    
    # Implementation based on tool type
    case $tool_name in
        crtsh)
            curl -s "https://crt.sh/?q=%25.$domain&output=json" 2>/dev/null | \
                grep -oP '(?<="common_name":")[^"]*' | \
                sort -u | grep -E "^.*\.$domain$|^$domain$" > "$output_file" 2>/dev/null || true
            ;;
        otx)
            curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$domain/passive_dns" 2>/dev/null | \
                grep -oP '"hostname":"[^"]*' | cut -d'"' -f4 | sort -u > "$output_file" 2>/dev/null || true
            ;;
        certspotter)
            curl -s "https://api.certspotter.com/v1/issuances?domain=$domain&include_subdomains=true&expand=dns_names" 2>/dev/null | \
                grep -oP '(?<="dns_names":\[")[^"]*|"dns_names":\["[^"]*' | grep -v "dns_names" | sort -u > "$output_file" 2>/dev/null || true
            ;;
        anubis)
            curl -s "https://jldc.me/anubis/subdomains/$domain" 2>/dev/null | \
                grep -oP '"[^"]*\.$domain"' | tr -d '"' | sort -u > "$output_file" 2>/dev/null || true
            ;;
        subdomaincenter)
            curl -s "https://api.subdomain.center/?domain=$domain" 2>/dev/null | \
                grep -oP '(?<="subdomain":")[^"]*' | sort -u > "$output_file" 2>/dev/null || true
            ;;
        virustotal)
            if [[ -n "$VIRUSTOTAL_API_KEY" ]]; then
                curl -s -H "x-apikey: $VIRUSTOTAL_API_KEY" \
                    "https://www.virustotal.com/api/v3/domains/$domain/subdomains?limit=40" 2>/dev/null | \
                    grep -oP '(?<="type":"domain","id":")[^"]*' | sort -u > "$output_file" 2>/dev/null || true
            fi
            ;;
        shodan)
            if [[ -n "$SHODAN_API_KEY" ]]; then
                curl -s "https://api.shodan.io/shodan/host/search?query=hostname:$domain&key=$SHODAN_API_KEY" 2>/dev/null | \
                    grep -oP '(?<="hostnames":\[")[^"]*|"hostnames":\["[^"]*' | grep -v "hostnames" | sort -u > "$output_file" 2>/dev/null || true
            fi
            ;;
    esac
}

# Wait for background jobs to complete
wait_for_jobs() {
    local max_jobs=$1
    local job_count=$(jobs -r | wc -l)
    while [[ $job_count -ge $max_jobs ]]; do
        sleep 0.5
        job_count=$(jobs -r | wc -l)
    done
}

# Probe subdomain for HTTP/HTTPS connectivity
probe_subdomain() {
    local subdomain=$1
    local output_file=$2
    
    # Try both HTTP and HTTPS
    for protocol in https http; do
        if curl -s -m "$HTTP_TIMEOUT" -o /dev/null -w "%{http_code}" "$protocol://$subdomain" 2>/dev/null | grep -q "^[23][0-9][0-9]$"; then
            echo "$subdomain ($protocol)" >> "$output_file"
            return 0
        fi
    done
    
    return 1
}

# Probe all discovered subdomains
probe_http_servers() {
    local combined_file=$1
    local probe_output="$OUTPUT_DIR/${TARGET}_http_probe_${TIMESTAMP}.txt"
    
    echo ""
    echo -e "${YELLOW}[*] Probing for live HTTP/HTTPS servers...${NC}"
    echo -e "${YELLOW}[*] This may take a while (timeout: ${HTTP_TIMEOUT}s per subdomain)${NC}"
    
    > "$probe_output"  # Initialize output file
    
    local total_found=0
    while IFS= read -r subdomain; do
        [[ -z "$subdomain" ]] && continue
        
        if probe_subdomain "$subdomain" "$probe_output"; then
            ((total_found++))
        fi
    done < "$combined_file"
    
    echo -e "${GREEN}[+] HTTP probe results saved to: $probe_output${NC}"
    echo -e "${GREEN}[+] Live servers found: $total_found${NC}"
}

# Generate metrics report
generate_metrics_report() {
    local combined_file=$1
    local metrics_file="$OUTPUT_DIR/${TARGET}_metrics_${TIMESTAMP}.txt"
    
    echo -e "\n${BLUE}Generating metrics report...${NC}" >&2
    
    # Calculate duration
    local start_timestamp=$START_TIME
    local end_timestamp=$END_TIME
    local duration=$((end_timestamp - start_timestamp))
    
    # Count unique subdomains
    local total_unique=$(cat "$combined_file" 2>/dev/null | wc -l)
    
    # Count subdomains per source
    local crtsh_count=$(cat "$OUTPUT_DIR/${TARGET}_crtsh_${TIMESTAMP}.txt" 2>/dev/null | wc -l)
    local otx_count=$(cat "$OUTPUT_DIR/${TARGET}_otx_${TIMESTAMP}.txt" 2>/dev/null | wc -l)
    local certspotter_count=$(cat "$OUTPUT_DIR/${TARGET}_certspotter_${TIMESTAMP}.txt" 2>/dev/null | wc -l)
    local anubis_count=$(cat "$OUTPUT_DIR/${TARGET}_anubis_${TIMESTAMP}.txt" 2>/dev/null | wc -l)
    local subdomaincenter_count=$(cat "$OUTPUT_DIR/${TARGET}_subdomaincenter_${TIMESTAMP}.txt" 2>/dev/null | wc -l)
    local virustotal_count=$(cat "$OUTPUT_DIR/${TARGET}_virustotal_${TIMESTAMP}.txt" 2>/dev/null | wc -l)
    local shodan_count=$(cat "$OUTPUT_DIR/${TARGET}_shodan_${TIMESTAMP}.txt" 2>/dev/null | wc -l)
    
    # Generate report
    {
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║          SerphunterRecon - Enumeration Report         ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        echo ""
        echo "TARGET: $TARGET"
        echo "TIMESTAMP: $TIMESTAMP"
        echo "EXECUTION TIME: ${duration}s"
        echo "EXECUTION MODE: $([ "$PARALLEL_MODE" = true ] && echo "Parallel" || echo "Sequential")"
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "ENUMERATION RESULTS BY SOURCE"
        echo "═══════════════════════════════════════════════════════"
        echo "CRT.SH:              $crtsh_count subdomains"
        echo "Alienvault OTX:      $otx_count subdomains"
        echo "Certspotter:         $certspotter_count subdomains"
        echo "JLDC Anubis:         $anubis_count subdomains"
        echo "Subdomain.center:    $subdomaincenter_count subdomains"
        echo "VirusTotal:          $virustotal_count subdomains"
        echo "Shodan:              $shodan_count subdomains"
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "SUMMARY STATISTICS"
        echo "═══════════════════════════════════════════════════════"
        echo "Total Unique Subdomains: $total_unique"
        echo "Execution Time: ${duration} seconds"
        echo "Average Time Per Source: $(echo "scale=2; $duration / 7" | bc) seconds"
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "RECOMMENDATIONS"
        echo "═══════════════════════════════════════════════════════"
        if [[ $total_unique -lt 10 ]]; then
            echo "⚠ Low number of subdomains found. Consider:"
            echo "  - Configuring API keys for additional sources"
            echo "  - Running additional manual reconnaissance"
        elif [[ $total_unique -lt 50 ]]; then
            echo "✓ Moderate number of subdomains found"
            echo "  - Consider HTTP probing for live services"
        else
            echo "✓ High number of subdomains found"
            echo "  - Run HTTP probing to identify live services"
        fi
        echo ""
        echo "═══════════════════════════════════════════════════════"
        
        if [[ -f "$OUTPUT_DIR/${TARGET}_http_probe_${TIMESTAMP}.txt" ]]; then
            local live_servers=$(cat "$OUTPUT_DIR/${TARGET}_http_probe_${TIMESTAMP}.txt" | wc -l)
            echo "HTTP PROBE RESULTS"
            echo "═══════════════════════════════════════════════════════"
            echo "Live Servers Found: $live_servers"
            echo ""
        fi
    } > "$metrics_file"
    
    cat "$metrics_file"
    echo -e "\n${GREEN}[+] Detailed report saved to: $metrics_file${NC}"
}

# Main execution
main() {
    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}Error: Domain is required${NC}"
        show_help
    fi
    
    START_TIME=$(date +%s)
    
    check_requirements
    load_config
    init_directories
    
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     SerphunterRecon - Enumeration      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Target: $TARGET${NC}"
    if [[ "$PARALLEL_MODE" == true ]]; then
        echo -e "${GREEN}Mode: Parallel (Max $MAX_JOBS jobs)${NC}"
    else
        echo -e "${GREEN}Mode: Sequential${NC}"
    fi
    echo ""
    
    if [[ "$PARALLEL_MODE" == true ]]; then
        # Run in parallel
        for tool in crtsh otx certspotter anubis subdomaincenter virustotal shodan; do
            wait_for_jobs $MAX_JOBS
            run_enumeration "$TARGET" "$tool" &
        done
        wait
    else
        # Run sequentially
        enumerate_crtsh "$TARGET"
        enumerate_otx "$TARGET"
        enumerate_certspotter "$TARGET"
        enumerate_anubis "$TARGET"
        enumerate_subdomain_center "$TARGET"
        enumerate_virustotal "$TARGET"
        enumerate_shodan "$TARGET"
    fi
    
    # Combine and deduplicate results
    local combined_file="$OUTPUT_DIR/${TARGET}_combined_${TIMESTAMP}.txt"
    cat "$OUTPUT_DIR"/${TARGET}_*_${TIMESTAMP}.txt 2>/dev/null | sort -u > "$combined_file"
    
    echo ""
    echo -e "${GREEN}[+] Final results saved to: $combined_file${NC}"
    echo -e "${GREEN}[+] Total unique subdomains: $(cat "$combined_file" | wc -l)${NC}"
    
    # Run HTTP probing if enabled
    if [[ "$PROBE_HTTP" == true ]]; then
        probe_http_servers "$combined_file"
    fi
    
    # Generate metrics report
    END_TIME=$(date +%s)
    if [[ "$ENABLE_METRICS" == true ]]; then
        generate_metrics_report "$combined_file"
    fi
}

# Execute main function
parse_arguments "$@"
main
