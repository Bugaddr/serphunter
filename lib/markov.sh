#!/bin/bash

# lib/markov.sh - Markov Chain Subdomain Prediction
# Learns character-level patterns from discovered subdomains to predict new ones.
# This is a novel application of statistical modeling in bash.

MARKOV_ORDER=3  # Trigram model
declare -A MARKOV_CHAIN
declare -A MARKOV_STARTS

# Build the Markov model from observed subdomains
train_markov_model() {
    local input_file=$1
    local target=$2
    
    log_info "Training Markov model on discovered subdomains..."
    
    # Reset model
    MARKOV_CHAIN=()
    MARKOV_STARTS=()
    
    local training_count=0
    
    while IFS= read -r subdomain; do
        [[ -z "$subdomain" ]] && continue
        
        # Strip the root domain to get the prefix
        local prefix=$(echo "$subdomain" | sed "s/\.$target$//")
        [[ -z "$prefix" || "$prefix" == "$subdomain" ]] && continue
        
        # Pad for start token
        local padded="^${prefix}$"
        local len=${#padded}
        
        # Record start sequences
        if [[ $len -ge $MARKOV_ORDER ]]; then
            local start="${padded:0:$MARKOV_ORDER}"
            MARKOV_STARTS["$start"]=$(( ${MARKOV_STARTS["$start"]:-0} + 1 ))
        fi
        
        # Build transition table
        for ((i=0; i<=len-MARKOV_ORDER-1; i++)); do
            local state="${padded:$i:$MARKOV_ORDER}"
            local next="${padded:$((i+MARKOV_ORDER)):1}"
            local key="${state}|${next}"
            MARKOV_CHAIN["$key"]=$(( ${MARKOV_CHAIN["$key"]:-0} + 1 ))
        done
        
        ((training_count++))
    done < "$input_file"
    
    log_success "Markov model trained on $training_count subdomains (${#MARKOV_CHAIN[@]} transitions)"
}

# Generate a single subdomain from the model
_generate_candidate() {
    local max_length=20
    
    # Pick a random start state weighted by frequency
    local total_starts=0
    for count in "${MARKOV_STARTS[@]}"; do
        total_starts=$((total_starts + count))
    done
    
    [[ $total_starts -eq 0 ]] && return 1
    
    local rand=$((RANDOM % total_starts))
    local current=""
    local cumulative=0
    
    for state in "${!MARKOV_STARTS[@]}"; do
        cumulative=$((cumulative + ${MARKOV_STARTS[$state]}))
        if [[ $cumulative -gt $rand ]]; then
            current="$state"
            break
        fi
    done
    
    # Generate characters until end token or max length
    local result="${current:1}"  # Strip the ^ start token
    
    for ((step=0; step<max_length; step++)); do
        # Collect possible next characters
        local candidates=()
        local weights=()
        local total_weight=0
        
        for key in "${!MARKOV_CHAIN[@]}"; do
            local k_state="${key%%|*}"
            local k_next="${key##*|}"
            
            if [[ "$k_state" == "${current}" ]]; then
                candidates+=("$k_next")
                weights+=(${MARKOV_CHAIN[$key]})
                total_weight=$((total_weight + ${MARKOV_CHAIN[$key]}))
            fi
        done
        
        [[ $total_weight -eq 0 ]] && break
        
        # Weighted random selection
        rand=$((RANDOM % total_weight))
        cumulative=0
        local chosen=""
        
        for ((j=0; j<${#candidates[@]}; j++)); do
            cumulative=$((cumulative + ${weights[$j]}))
            if [[ $cumulative -gt $rand ]]; then
                chosen="${candidates[$j]}"
                break
            fi
        done
        
        [[ "$chosen" == '$' ]] && break  # End token
        
        result+="$chosen"
        current="${current:1}${chosen}"  # Slide window
    done
    
    # Clean up result
    result=$(echo "$result" | tr -cd 'a-z0-9.-')
    [[ -n "$result" && ${#result} -gt 2 ]] && echo "$result" || return 1
}

# Generate and verify predicted subdomains
run_markov_prediction() {
    local target=$1
    local combined_file=$2
    local num_candidates=${3:-50}
    local output_file="$OUTPUT_DIR/${target}_markov_${TIMESTAMP}.txt"
    local verified_file="$OUTPUT_DIR/${target}_markov_verified_${TIMESTAMP}.txt"
    
    # Train the model
    train_markov_model "$combined_file" "$target"
    
    log_info "Generating $num_candidates Markov-predicted candidates..."
    
    > "$output_file"
    > "$verified_file"
    
    local generated=0
    local verified=0
    local attempts=0
    local max_attempts=$((num_candidates * 3))
    
    while [[ $generated -lt $num_candidates && $attempts -lt $max_attempts ]]; do
        ((attempts++))
        
        local candidate=$(_generate_candidate)
        [[ -z "$candidate" ]] && continue
        
        local full_domain="${candidate}.${target}"
        
        # Skip if already known
        grep -q "^${full_domain}$" "$combined_file" 2>/dev/null && continue
        
        echo "$full_domain" >> "$output_file"
        ((generated++))
        
        # Active verification
        if curl -s -m 3 -o /dev/null -w "%{http_code}" "http://${full_domain}" 2>/dev/null | grep -q "^[23]..$"; then
            echo "$full_domain" >> "$verified_file"
            ((verified++))
            log_success "MARKOV HIT: $full_domain is live!"
        fi
    done
    
    log_info "Generated $generated candidates, verified $verified as live"
    log_success "Markov predictions saved to: $output_file"
}
