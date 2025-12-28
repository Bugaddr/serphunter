#!/bin/bash

# modules/takeover.sh - Subdomain Takeover Detection
# Checks for dangling CNAME records pointing to claimable services

# Known vulnerable CNAME fingerprints
declare -A TAKEOVER_SIGNATURES=(
    ["s3.amazonaws.com"]="NoSuchBucket"
    ["github.io"]="There isn't a GitHub Pages site here"
    ["herokuapp.com"]="No such app"
    ["pantheon.io"]="404 error unknown site"
    ["readme.io"]="Project doesnt exist"
    ["surge.sh"]="project not found"
    ["bitbucket.io"]="Repository not found"
    ["ghost.io"]="The thing you were looking for is no longer here"
    ["myshopify.com"]="Sorry, this shop is currently unavailable"
    ["feedpress.me"]="The feed has not been found"
    ["freshdesk.com"]="There is no helpdesk here"
    ["zendesk.com"]="Help Center Closed"
    ["azure-api.net"]="The resource you are looking for has been removed"
    ["cloudapp.net"]="The resource you are looking for has been removed"
    ["trafficmanager.net"]="404 Not Found"
    ["azurewebsites.net"]="Web App - Unavailable"
    ["cloudfront.net"]="Bad Request"
    ["elasticbeanstalk.com"]="404 Not Found"
    ["agilecrm.com"]="Sorry, this page is no longer available"
    ["unbounce.com"]="The requested URL was not found on this server"
    ["smartling.com"]="Domain is not configured"
    ["acquia-test.co"]="Web Site Not Found"
    ["proposify.biz"]="If you need immediate assistance"
    ["simplebooklet.com"]="We can't find this SimpleBooklet"
    ["getresponse.com"]="With GetResponse Landing Pages"
    ["cargocollective.com"]="404 Not Found"
    ["statuspage.io"]="You are being redirected"
    ["helpjuice.com"]="We could not find what you're looking for"
    ["helpscout.net"]="No settings were found"
    ["canny.io"]="Company Not Found"
    ["tilda.cc"]="Please renew your subscription"
)

run_takeover() {
    local target=$1
    local combined_file=$2
    local output_file="$OUTPUT_DIR/${target}_takeover_${TIMESTAMP}.txt"
    local vuln_count=0
    
    log_info "Checking for subdomain takeover vulnerabilities..."
    
    > "$output_file"
    
    while IFS= read -r subdomain; do
        [[ -z "$subdomain" ]] && continue
        
        # Step 1: Get CNAME record
        local cname=$(dig +short CNAME "$subdomain" 2>/dev/null | head -1 | sed 's/\.$//')
        [[ -z "$cname" ]] && continue
        
        # Step 2: Check if CNAME matches any vulnerable service
        for service_pattern in "${!TAKEOVER_SIGNATURES[@]}"; do
            if [[ "$cname" == *"$service_pattern"* ]]; then
                local fingerprint="${TAKEOVER_SIGNATURES[$service_pattern]}"
                
                # Step 3: Verify by fetching the page
                local body=$(curl -sL -m 5 "http://$subdomain" 2>/dev/null)
                
                if echo "$body" | grep -qi "$fingerprint" 2>/dev/null; then
                    echo "[VULNERABLE] $subdomain -> $cname ($service_pattern)" >> "$output_file"
                    log_warning "TAKEOVER POSSIBLE: $subdomain -> $cname"
                    ((vuln_count++))
                else
                    echo "[CNAME MATCH] $subdomain -> $cname (not confirmed)" >> "$output_file"
                fi
                break
            fi
        done
    done < "$combined_file"
    
    if [[ $vuln_count -gt 0 ]]; then
        log_warning "Found $vuln_count potential takeover vulnerabilities!"
    else
        log_success "No takeover vulnerabilities detected."
    fi
}
