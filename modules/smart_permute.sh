#!/bin/bash

# modules/smart_permute.sh - Smart Pattern Recognition & Permutation
# Novelty: Uses heuristic analysis of found subdomains to predict new ones.

run_smart_permute() {
    local target=$1
    local existing_results=${2:-}
    
    if [[ -z "$existing_results" || ! -f "$existing_results" ]]; then
        return 0  # Skip when called as plugin without combined file
    fi
    local output_file="$OUTPUT_DIR/${target}_smart_permute_${TIMESTAMP}.txt"
    
    log_info "Running Smart Pattern Recognition (AI Heuristics)..."
    
    # 1. Analyze existing results to find common environments (dev, stg, prod)
    local has_dev=$(grep -q "dev" "$existing_results" && echo "true" || echo "false")
    local has_stg=$(grep -q "stg\|stage\|staging" "$existing_results" && echo "true" || echo "false")
    local has_prod=$(grep -q "prod" "$existing_results" && echo "true" || echo "false")
    
    # 2. Extract base words from subdomains (e.g., api.dev.example.com -> api)
    # Simplified extraction for bash
    local base_words=$(cat "$existing_results" | sed "s/\.$target//g" | tr '.' '\n' | sort | uniq -c | sort -nr | head -n 5 | awk '{print $2}')
    
    # 3. Generate Permutations based on missing environments
    > "$output_file"
    
    for word in $base_words; do
        # If we have 'dev', try 'stage' and 'prod' variations
        if [[ "$has_dev" == "true" ]]; then
           echo "${word}.stage.${target}" >> "$output_file"
           echo "${word}.prod.${target}" >> "$output_file"
        fi
        
        # Common permutations
        echo "dev-${word}.${target}" >> "$output_file"
        echo "prod-${word}.${target}" >> "$output_file"
        echo "${word}-internal.${target}" >> "$output_file"
    done
    
    # 4. Verify generated permutations (Active Resolution)
    local verified_count=0
    local confirmed_file="$OUTPUT_DIR/${target}_smart_permute_verified_${TIMESTAMP}.txt"
    
    log_info "Verifying AI-predicted candidates..."
    while read -r candidate; do
        if curl -s -m 3 -o /dev/null -w "%{http_code}" "http://${candidate}" 2>/dev/null | grep -q "^[23]..$"; then
            echo "$candidate" >> "$confirmed_file"
            ((verified_count++)) || true
        fi
    done < "$output_file"
    
    if [[ $verified_count -gt 0 ]]; then
        log_success "Smart Pattern Recognition found $verified_count new hidden subdomains!"
        cat "$confirmed_file" >> "$output_file" # Combine for final reporting
    else
        log_info "No new subdomains found via heuristics."
    fi
}
