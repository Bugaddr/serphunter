#!/bin/bash

# lib/risk.sh - Risk Scoring Engine
# Assigns a composite risk score to each subdomain based on multiple factors

# Risk weights
WEIGHT_EXPOSURE=30      # Is it internet-facing?
WEIGHT_SECURITY=25      # Does it have security headers?
WEIGHT_TAKEOVER=25      # Is it vulnerable to takeover?
WEIGHT_SENSITIVE=20     # Does it contain sensitive keywords?

# Sensitive keyword patterns (high-risk indicators)
SENSITIVE_KEYWORDS=(
    "admin" "login" "staging" "dev" "test" "debug"
    "internal" "api" "dashboard" "panel" "console"
    "backup" "legacy" "old" "temp" "vpn" "remote"
    "jenkins" "gitlab" "jira" "confluence" "grafana"
    "phpmyadmin" "wp-admin" "kibana" "elastic"
    "mongo" "redis" "mysql" "postgres" "database"
)

calculate_risk_score() {
    local subdomain=$1
    local is_live=$2         # 0 or 1
    local sec_score=$3       # 0-100
    local is_takeover=$4     # 0 or 1
    local total_score=0
    
    # Factor 1: Exposure (live = higher risk because it's accessible)
    if [[ "$is_live" -eq 1 ]]; then
        total_score=$((total_score + WEIGHT_EXPOSURE))
    fi
    
    # Factor 2: Security Posture (inverted: lower security = higher risk)
    if [[ $sec_score -lt 25 ]]; then
        total_score=$((total_score + WEIGHT_SECURITY))
    elif [[ $sec_score -lt 50 ]]; then
        total_score=$((total_score + WEIGHT_SECURITY / 2))
    fi
    
    # Factor 3: Takeover Risk
    if [[ "$is_takeover" -eq 1 ]]; then
        total_score=$((total_score + WEIGHT_TAKEOVER))
    fi
    
    # Factor 4: Sensitive Keyword Match
    for keyword in "${SENSITIVE_KEYWORDS[@]}"; do
        if echo "$subdomain" | grep -qi "$keyword"; then
            total_score=$((total_score + WEIGHT_SENSITIVE))
            break  # Only count once
        fi
    done
    
    echo "$total_score"
}

classify_risk() {
    local score=$1
    
    if [[ $score -ge 75 ]]; then
        echo "CRITICAL"
    elif [[ $score -ge 50 ]]; then
        echo "HIGH"
    elif [[ $score -ge 25 ]]; then
        echo "MEDIUM"
    else
        echo "LOW"
    fi
}

run_risk_assessment() {
    local target=$1
    local combined_file=$2
    local output_file="$OUTPUT_DIR/${target}_risk_${TIMESTAMP}.txt"
    
    log_info "Running risk assessment..."
    
    # Header
    printf "%-50s %-10s %-10s\n" "SUBDOMAIN" "SCORE" "RISK" > "$output_file"
    printf "%-50s %-10s %-10s\n" "$(printf '%.0s─' {1..50})" "──────" "──────" >> "$output_file"
    
    local critical=0 high=0 medium=0 low=0
    
    while IFS= read -r subdomain; do
        [[ -z "$subdomain" ]] && continue
        
        # Check if live
        local is_live=0
        curl -s -m 3 -o /dev/null "http://$subdomain" 2>/dev/null && is_live=1
        
        # Simplified security check
        local sec_score=0
        local headers=$(curl -sI -m 3 "https://$subdomain" 2>/dev/null)
        echo "$headers" | grep -qi "Strict-Transport-Security" && sec_score=$((sec_score+25))
        echo "$headers" | grep -qi "Content-Security-Policy" && sec_score=$((sec_score+25))
        echo "$headers" | grep -qi "X-Frame-Options" && sec_score=$((sec_score+25))
        echo "$headers" | grep -qi "X-Content-Type-Options" && sec_score=$((sec_score+25))
        
        # Check takeover
        local is_takeover=0
        # (Would check against takeover results if available)
        
        local score=$(calculate_risk_score "$subdomain" "$is_live" "$sec_score" "$is_takeover")
        local risk=$(classify_risk "$score")
        
        printf "%-50s %-10s %-10s\n" "$subdomain" "$score" "$risk" >> "$output_file"
        
        case "$risk" in
            CRITICAL) ((critical++)) ;;
            HIGH)     ((high++)) ;;
            MEDIUM)   ((medium++)) ;;
            LOW)      ((low++)) ;;
        esac
    done < "$combined_file"
    
    echo "" >> "$output_file"
    echo "RISK DISTRIBUTION:" >> "$output_file"
    echo "  CRITICAL: $critical" >> "$output_file"
    echo "  HIGH:     $high" >> "$output_file"
    echo "  MEDIUM:   $medium" >> "$output_file"
    echo "  LOW:      $low" >> "$output_file"
    
    log_success "Risk assessment complete: $critical critical, $high high, $medium medium, $low low"
}
