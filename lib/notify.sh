#!/bin/bash

# lib/notify.sh - Webhook Notification System
# Sends scan results to Slack/Discord channels

SLACK_WEBHOOK_URL=""
DISCORD_WEBHOOK_URL=""

load_notification_config() {
    SLACK_WEBHOOK_URL="${SLACK_WEBHOOK:-}"
    DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK:-}"
    
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        log_info "Slack notifications enabled"
    fi
    if [[ -n "$DISCORD_WEBHOOK_URL" ]]; then
        log_info "Discord notifications enabled"
    fi
}

# Format message payload
_build_payload() {
    local target=$1
    local total=$2
    local new_count=$3
    local duration=$4
    
    cat <<EOF
{
    "text": "🔍 **SerphunterRecon Scan Complete**",
    "blocks": [
        {
            "type": "header",
            "text": "SerphunterRecon - Scan Results"
        },
        {
            "fields": [
                {"title": "Target", "value": "$target"},
                {"title": "Total Subdomains", "value": "$total"},
                {"title": "New Since Last Scan", "value": "$new_count"},
                {"title": "Duration", "value": "${duration}s"}
            ]
        }
    ]
}
EOF
}

# Send notification to Slack
notify_slack() {
    local target=$1
    local total=$2
    local new_count=${3:-0}
    local duration=${4:-0}
    
    [[ -z "$SLACK_WEBHOOK_URL" ]] && return
    
    local payload=$(_build_payload "$target" "$total" "$new_count" "$duration")
    
    if curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" "$SLACK_WEBHOOK_URL" > /dev/null 2>&1; then
        log_success "Slack notification sent"
    else
        log_error "Failed to send Slack notification"
    fi
}

# Send notification to Discord
notify_discord() {
    local target=$1
    local total=$2
    local new_count=${3:-0}
    local duration=${4:-0}
    
    [[ -z "$DISCORD_WEBHOOK_URL" ]] && return
    
    local payload=$(jq -n \
        --arg target "$target" \
        --arg total "$total" \
        --arg new "$new_count" \
        --arg dur "$duration" \
        '{
            "embeds": [{
                "title": "SerphunterRecon Scan Complete",
                "color": 3066993,
                "fields": [
                    {"name": "Target", "value": $target, "inline": true},
                    {"name": "Subdomains", "value": $total, "inline": true},
                    {"name": "New Assets", "value": $new, "inline": true},
                    {"name": "Duration", "value": ($dur + "s"), "inline": true}
                ]
            }]
        }')
    
    if curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" "$DISCORD_WEBHOOK_URL" > /dev/null 2>&1; then
        log_success "Discord notification sent"
    else
        log_error "Failed to send Discord notification"
    fi
}

# Send to all configured channels
notify_all() {
    local target=$1
    local total=$2
    local new_count=${3:-0}
    local duration=${4:-0}
    
    notify_slack "$target" "$total" "$new_count" "$duration"
    notify_discord "$target" "$total" "$new_count" "$duration"
}
