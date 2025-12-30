#!/bin/bash

# lib/scope.sh - Scope Manager
# Filters results based on user-defined in-scope/out-of-scope rules

SCOPE_FILE=""
IN_SCOPE_PATTERNS=()
OUT_OF_SCOPE_PATTERNS=()

load_scope() {
    SCOPE_FILE="$1"
    
    if [[ ! -f "$SCOPE_FILE" ]]; then
        log_warning "No scope file provided. All results are in-scope."
        return
    fi
    
    log_info "Loading scope rules from $SCOPE_FILE"
    
    local section=""
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        
        case "$line" in
            "[in-scope]")  section="in" ;;
            "[out-of-scope]") section="out" ;;
            *)
                if [[ "$section" == "in" ]]; then
                    IN_SCOPE_PATTERNS+=("$line")
                elif [[ "$section" == "out" ]]; then
                    OUT_OF_SCOPE_PATTERNS+=("$line")
                fi
                ;;
        esac
    done < "$SCOPE_FILE"
    
    log_success "Loaded ${#IN_SCOPE_PATTERNS[@]} in-scope, ${#OUT_OF_SCOPE_PATTERNS[@]} out-of-scope rules"
}

# Check if a subdomain is within scope
is_in_scope() {
    local subdomain=$1
    
    # If no scope rules, everything is in scope
    if [[ ${#IN_SCOPE_PATTERNS[@]} -eq 0 && ${#OUT_OF_SCOPE_PATTERNS[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Check out-of-scope first (deny takes priority)
    for pattern in "${OUT_OF_SCOPE_PATTERNS[@]}"; do
        if [[ "$subdomain" =~ $pattern ]]; then
            return 1
        fi
    done
    
    # If in-scope rules exist, must match at least one
    if [[ ${#IN_SCOPE_PATTERNS[@]} -gt 0 ]]; then
        for pattern in "${IN_SCOPE_PATTERNS[@]}"; do
            if [[ "$subdomain" =~ $pattern ]]; then
                return 0
            fi
        done
        return 1  # Didn't match any in-scope rule
    fi
    
    return 0
}

# Apply scope filtering to a results file
apply_scope_filter() {
    local input_file=$1
    local output_file=$2
    local filtered_count=0
    local total_count=0
    
    log_info "Applying scope filter..."
    
    > "$output_file"
    
    while IFS= read -r subdomain; do
        [[ -z "$subdomain" ]] && continue
        ((total_count++)) || true
        
        if is_in_scope "$subdomain"; then
            echo "$subdomain" >> "$output_file"
        else
            ((filtered_count++)) || true
        fi
    done < "$input_file"
    
    local kept=$((total_count - filtered_count))
    log_success "Scope filter: $kept in-scope, $filtered_count out-of-scope (from $total_count total)"
}
