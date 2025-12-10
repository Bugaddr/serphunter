#!/bin/bash

###############################################################################
# SerphunterRecon - Performance Benchmark Script
# Measures and compares sequential vs parallel execution
# Generates detailed performance metrics and analysis
###############################################################################

set -e

# Color codes
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
MAGENTA='\033[95m'
CYAN='\033[96m'
NC='\033[0m'

# Benchmark variables
BENCHMARK_DIR="benchmarks"
RESULTS_DIR="benchmark_results"
TEST_DOMAINS=("google.com" "example.com" "github.com")
RUNS=3

# Create benchmark directory structure
setup_benchmark_env() {
    mkdir -p "$RESULTS_DIR"
    mkdir -p "$BENCHMARK_DIR/logs"
    echo -e "${GREEN}[✓] Benchmark environment initialized${NC}"
}

# Display benchmark header
show_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     SerphunterRecon - Performance Benchmark Suite         ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Benchmark sequential execution
benchmark_sequential() {
    local domain=$1
    local benchmark_file="$RESULTS_DIR/${domain}_sequential_benchmark.txt"
    
    echo -e "${YELLOW}[*] Benchmarking sequential mode for: $domain${NC}"
    
    # Warm-up run
    timeout 120 ./serphunter.sh -d "$domain" > /dev/null 2>&1 || true
    
    # Actual benchmark runs
    local total_time=0
    local run_times=()
    
    for ((i=1; i<=RUNS; i++)); do
        echo -e "${CYAN}  Run $i/$RUNS...${NC}"
        
        # Measure execution time
        local start_time=$(date +%s%N)
        timeout 120 ./serphunter.sh -d "$domain" > /tmp/seq_output_$i.txt 2>&1 || true
        local end_time=$(date +%s%N)
        
        # Convert nanoseconds to seconds
        local duration=$(( (end_time - start_time) / 1000000 ))
        local duration_sec=$(echo "scale=2; $duration / 1000" | bc)
        
        run_times+=($duration_sec)
        total_time=$(echo "$total_time + $duration_sec" | bc)
        
        # Count results
        local result_count=$(cat "$RESULTS_DIR"/${domain}_combined_*.txt 2>/dev/null | wc -l || echo 0)
        echo "    Time: ${duration_sec}s | Results: $result_count"
    done
    
    # Calculate averages
    local avg_time=$(echo "scale=2; $total_time / $RUNS" | bc)
    local min_time=$(echo "${run_times[@]}" | tr ' ' '\n' | sort -n | head -1)
    local max_time=$(echo "${run_times[@]}" | tr ' ' '\n' | sort -n | tail -1)
    
    # Save results
    {
        echo "Sequential Mode Benchmark - $domain"
        echo "=================================="
        echo "Runs: $RUNS"
        echo "Average Time: ${avg_time}s"
        echo "Min Time: ${min_time}s"
        echo "Max Time: ${max_time}s"
        echo "Total Time: ${total_time}s"
        echo ""
        echo "Individual Run Times:"
        for ((i=0; i<${#run_times[@]}; i++)); do
            echo "  Run $((i+1)): ${run_times[i]}s"
        done
    } > "$benchmark_file"
    
    echo -e "${GREEN}[✓] Sequential benchmark saved${NC}"
    echo "$avg_time"
}

# Benchmark parallel execution
benchmark_parallel() {
    local domain=$1
    local benchmark_file="$RESULTS_DIR/${domain}_parallel_benchmark.txt"
    
    echo -e "${YELLOW}[*] Benchmarking parallel mode for: $domain${NC}"
    
    # Warm-up run
    timeout 120 ./serphunter.sh -d "$domain" -p > /dev/null 2>&1 || true
    
    # Actual benchmark runs
    local total_time=0
    local run_times=()
    
    for ((i=1; i<=RUNS; i++)); do
        echo -e "${CYAN}  Run $i/$RUNS...${NC}"
        
        # Measure execution time
        local start_time=$(date +%s%N)
        timeout 120 ./serphunter.sh -d "$domain" -p > /tmp/par_output_$i.txt 2>&1 || true
        local end_time=$(date +%s%N)
        
        # Convert nanoseconds to seconds
        local duration=$(( (end_time - start_time) / 1000000 ))
        local duration_sec=$(echo "scale=2; $duration / 1000" | bc)
        
        run_times+=($duration_sec)
        total_time=$(echo "$total_time + $duration_sec" | bc)
        
        # Count results
        local result_count=$(cat "$RESULTS_DIR"/${domain}_combined_*.txt 2>/dev/null | wc -l || echo 0)
        echo "    Time: ${duration_sec}s | Results: $result_count"
    done
    
    # Calculate averages
    local avg_time=$(echo "scale=2; $total_time / $RUNS" | bc)
    local min_time=$(echo "${run_times[@]}" | tr ' ' '\n' | sort -n | head -1)
    local max_time=$(echo "${run_times[@]}" | tr ' ' '\n' | sort -n | tail -1)
    
    # Save results
    {
        echo "Parallel Mode Benchmark - $domain"
        echo "=================================="
        echo "Runs: $RUNS"
        echo "Average Time: ${avg_time}s"
        echo "Min Time: ${min_time}s"
        echo "Max Time: ${max_time}s"
        echo "Total Time: ${total_time}s"
        echo ""
        echo "Individual Run Times:"
        for ((i=0; i<${#run_times[@]}; i++)); do
            echo "  Run $((i+1)): ${run_times[i]}s"
        done
    } > "$benchmark_file"
    
    echo -e "${GREEN}[✓] Parallel benchmark saved${NC}"
    echo "$avg_time"
}

# Compare results
compare_modes() {
    local domain=$1
    local seq_time=$2
    local par_time=$3
    local comparison_file="$RESULTS_DIR/${domain}_comparison.txt"
    
    # Calculate improvement
    local improvement=$(echo "scale=2; (($seq_time - $par_time) / $seq_time) * 100" | bc)
    local speedup=$(echo "scale=2; $seq_time / $par_time" | bc)
    
    {
        echo "Performance Comparison - $domain"
        echo "================================"
        echo "Sequential Mode Average: ${seq_time}s"
        echo "Parallel Mode Average: ${par_time}s"
        echo ""
        echo "Performance Improvement:"
        echo "  Time Saved: $(echo "scale=2; $seq_time - $par_time" | bc)s"
        echo "  Percentage Improvement: ${improvement}%"
        echo "  Speedup Factor: ${speedup}x"
        echo ""
        echo "Verdict:"
        if (( $(echo "$improvement > 50" | bc -l) )); then
            echo "  ✓ EXCELLENT: Parallel mode is significantly faster"
        elif (( $(echo "$improvement > 25" | bc -l) )); then
            echo "  ✓ GOOD: Parallel mode provides substantial speedup"
        else
            echo "  ~ NEUTRAL: Minimal difference between modes"
        fi
    } > "$comparison_file"
    
    cat "$comparison_file"
}

# Generate summary report
generate_summary_report() {
    local report_file="$RESULTS_DIR/BENCHMARK_SUMMARY_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "════════════════════════════════════════════════════════════"
        echo "           SerphunterRecon Benchmark Report"
        echo "════════════════════════════════════════════════════════════"
        echo ""
        echo "Benchmark Date: $(date)"
        echo "Test Runs per Mode: $RUNS"
        echo "Domains Tested: ${#TEST_DOMAINS[@]}"
        echo ""
        
        for domain in "${TEST_DOMAINS[@]}"; do
            if [[ -f "$RESULTS_DIR/${domain}_comparison.txt" ]]; then
                cat "$RESULTS_DIR/${domain}_comparison.txt"
                echo ""
            fi
        done
        
        echo "════════════════════════════════════════════════════════════"
        echo "Files Generated:"
        echo "════════════════════════════════════════════════════════════"
        ls -lh "$RESULTS_DIR" | tail -n +2 | awk '{print "  " $9 " (" $5 ")"}'
        
    } > "$report_file"
    
    cat "$report_file"
    echo -e "\n${GREEN}[✓] Summary report saved to: $report_file${NC}"
}

# Main benchmark execution
main() {
    show_header
    setup_benchmark_env
    
    echo ""
    echo -e "${MAGENTA}Starting Performance Benchmarks...${NC}"
    echo ""
    
    for domain in "${TEST_DOMAINS[@]}"; do
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}Testing: $domain${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        seq_time=$(benchmark_sequential "$domain")
        echo ""
        par_time=$(benchmark_parallel "$domain")
        echo ""
        
        compare_modes "$domain" "$seq_time" "$par_time"
        echo ""
    done
    
    echo ""
    echo -e "${MAGENTA}Generating Summary Report...${NC}"
    echo ""
    generate_summary_report
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Benchmark Complete - Results Saved              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Results directory: $RESULTS_DIR${NC}"
    echo -e "${CYAN}View detailed results: ls -la $RESULTS_DIR/${NC}"
}

# Execute main function
main "$@"
