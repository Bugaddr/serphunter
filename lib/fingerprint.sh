#!/bin/bash

# lib/fingerprint.sh - Technology Fingerprinting Engine
# Identifies technologies running on subdomains via HTTP response headers

declare -A TECH_PATTERNS

init_fingerprint_db() {
    # Web Servers
    TECH_PATTERNS["Server: nginx"]="Nginx"
    TECH_PATTERNS["Server: Apache"]="Apache"
    TECH_PATTERNS["Server: Microsoft-IIS"]="IIS"
    TECH_PATTERNS["Server: cloudflare"]="Cloudflare"
    TECH_PATTERNS["Server: AmazonS3"]="AWS S3"
    TECH_PATTERNS["Server: gws"]="Google Web Server"
    TECH_PATTERNS["Server: openresty"]="OpenResty"
    TECH_PATTERNS["Server: LiteSpeed"]="LiteSpeed"
    
    # Frameworks
    TECH_PATTERNS["X-Powered-By: Express"]="Node.js/Express"
    TECH_PATTERNS["X-Powered-By: PHP"]="PHP"
    TECH_PATTERNS["X-Powered-By: ASP.NET"]="ASP.NET"
    TECH_PATTERNS["X-Powered-By: Next.js"]="Next.js"
    TECH_PATTERNS["X-Powered-By: Phusion Passenger"]="Ruby/Passenger"
    
    # CDN / Proxy
    TECH_PATTERNS["X-Cache"]="CDN Cached"
    TECH_PATTERNS["CF-RAY"]="Cloudflare CDN"
    TECH_PATTERNS["X-Amz-Cf-Id"]="AWS CloudFront"
    TECH_PATTERNS["X-Fastly-Request-ID"]="Fastly CDN"
    TECH_PATTERNS["X-Served-By: cache"]="Varnish Cache"
    TECH_PATTERNS["Via: varnish"]="Varnish"
    
    # Security Headers (presence = good security posture)
    TECH_PATTERNS["Strict-Transport-Security"]="HSTS Enabled"
    TECH_PATTERNS["Content-Security-Policy"]="CSP Enabled"
    TECH_PATTERNS["X-Frame-Options"]="Clickjacking Protection"
    TECH_PATTERNS["X-Content-Type-Options"]="MIME Sniffing Protection"
    
    # CMS
    TECH_PATTERNS["X-Drupal"]="Drupal CMS"
    TECH_PATTERNS["X-Generator: WordPress"]="WordPress"
    TECH_PATTERNS["X-Shopify-Stage"]="Shopify"
}

fingerprint_subdomain() {
    local subdomain=$1
    local detected=()
    
    # Fetch headers
    local headers=$(curl -sI -m 5 "https://$subdomain" 2>/dev/null)
    [[ -z "$headers" ]] && headers=$(curl -sI -m 5 "http://$subdomain" 2>/dev/null)
    [[ -z "$headers" ]] && return
    
    # Match against known patterns
    for pattern in "${!TECH_PATTERNS[@]}"; do
        if echo "$headers" | grep -qi "$pattern" 2>/dev/null; then
            detected+=("${TECH_PATTERNS[$pattern]}")
        fi
    done
    
    # Check security score
    local sec_score=0
    echo "$headers" | grep -qi "Strict-Transport-Security" && ((sec_score+=25))
    echo "$headers" | grep -qi "Content-Security-Policy" && ((sec_score+=25))
    echo "$headers" | grep -qi "X-Frame-Options" && ((sec_score+=25))
    echo "$headers" | grep -qi "X-Content-Type-Options" && ((sec_score+=25))
    
    if [[ ${#detected[@]} -gt 0 ]]; then
        echo "$subdomain|$(IFS=,; echo "${detected[*]}")|$sec_score"
    fi
}

run_fingerprint() {
    local target=$1
    local combined_file=$2
    local output_file="$OUTPUT_DIR/${target}_fingerprint_${TIMESTAMP}.txt"
    
    init_fingerprint_db
    log_info "Running technology fingerprinting..."
    
    echo "SUBDOMAIN|TECHNOLOGIES|SECURITY_SCORE" > "$output_file"
    
    local scanned=0
    while IFS= read -r subdomain; do
        [[ -z "$subdomain" ]] && continue
        
        local result=$(fingerprint_subdomain "$subdomain")
        if [[ -n "$result" ]]; then
            echo "$result" >> "$output_file"
        fi
        ((scanned++)) || true
        echo -ne "\r[*] Fingerprinted: $scanned"
    done < "$combined_file"
    echo ""
    
    local found=$(($(wc -l < "$output_file") - 1))
    log_success "Fingerprinted $found subdomains. Results: $output_file"
}
