#!/bin/bash

###############################################################################
# SerphunterRecon - Quick Benchmark (Single Run)
# Fast performance measurement for continuous integration/testing
###############################################################################

set -e

# Color codes
BLUE='\033[94m'
GREEN='\033[92m'
YELLOW='\033[93m'
RED='\033[91m'
NC='\033[0m'

# Default domain
DOMAIN="${1:-example.com}"
OUTPUT_DIR="benchmark_results"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Display header
show_header() {
    echo -e "${BLUE}SerphunterRecon - Quick Benchmark${NC}"
    echo "Domain: $DOMAIN"
    echo ""
}

# Run quick benchmark
run_benchmark() {
    local mode=$1
    local mode_name=$2
    local output_file="$OUTPUT_DIR/quick_${mode}_${DOMAIN}_$(date +%s).txt"
    
    echo -e "${YELLOW}[*] Running $mode_name mode...${NC}"
    
    # Start timer
    local start=$(date +%s%N)
    
    # Execute based on mode
    if [[ "$mode" == "seq" ]]; then
        timeout 120 ./serphunter.sh -d "$DOMAIN" > "$output_file" 2>&1 || true
    else
        timeout 120 ./serphunter.sh -d "$DOMAIN" --parallel > "$output_file" 2>&1 || true
    fi
    
    # End timer
    local end=$(date +%s%N)
    local duration_ms=$(( (end - start) / 1000000 ))
    local duration_sec=$(echo "scale=2; $duration_ms / 1000" | bc)
    
    # Count results
    local result_file="$OUTPUT_DIR/${DOMAIN}_combined_*.txt"
    local result_count=$(cat $result_file 2>/dev/null | wc -l || echo 0)
    
    echo -e "${GREEN}[✓] Completed in ${duration_sec}s${NC}"
    echo -e "${GREEN}[+] Results found: $result_count${NC}"
    
    echo "$duration_sec"
}

# Display results
display_results() {
    local seq_time=$1
    local par_time=$2
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Performance Results           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "Sequential Mode:  ${YELLOW}${seq_time}s${NC}"
    echo -e "Parallel Mode:    ${GREEN}${par_time}s${NC}"
    
    local improvement=$(echo "scale=1; (($seq_time - $par_time) / $seq_time) * 100" | bc)
    local speedup=$(echo "scale=2; $seq_time / $par_time" | bc)
    
    echo ""
    echo -e "⚡ Performance Improvement: ${YELLOW}${improvement}%${NC}"
    echo -e "🚀 Speedup Factor: ${GREEN}${speedup}x${NC}"
    echo ""
}

# Main
main() {
    show_header
    
    seq_time=$(run_benchmark "seq" "Sequential")
    echo ""
    par_time=$(run_benchmark "par" "Parallel")
    
    display_results "$seq_time" "$par_time"
}

main "$@"
