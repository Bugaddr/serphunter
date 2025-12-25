#!/bin/bash

# lib/ratelimit.sh - Token Bucket Rate Limiter
# Prevents API abuse and IP blocking during enumeration

RATE_LIMIT_DIR="/tmp/serphunter_ratelimit"
DEFAULT_RATE=5          # requests per window
DEFAULT_WINDOW=10       # seconds

init_rate_limiter() {
    mkdir -p "$RATE_LIMIT_DIR"
    log_info "Rate limiter initialized (${DEFAULT_RATE} req/${DEFAULT_WINDOW}s)"
}

# Get a token from the bucket for a specific API source
# Blocks if no tokens are available (backpressure)
acquire_token() {
    local source_name=$1
    local max_rate=${2:-$DEFAULT_RATE}
    local window=${3:-$DEFAULT_WINDOW}
    local bucket_file="$RATE_LIMIT_DIR/${source_name}.bucket"
    local lock_file="$RATE_LIMIT_DIR/${source_name}.lock"

    # Simple file-based locking for concurrency safety
    while ! mkdir "$lock_file" 2>/dev/null; do
        sleep 0.1
    done

    # Read current bucket state
    local now=$(date +%s)
    local tokens=$max_rate
    local last_refill=$now

    if [[ -f "$bucket_file" ]]; then
        local stored_tokens=$(sed -n '1p' "$bucket_file")
        local stored_time=$(sed -n '2p' "$bucket_file")

        # Calculate tokens to add based on elapsed time
        local elapsed=$((now - stored_time))
        local refill=$((elapsed * max_rate / window))
        tokens=$((stored_tokens + refill))

        # Cap at max
        if [[ $tokens -gt $max_rate ]]; then
            tokens=$max_rate
        fi
    fi

    # Check if we have tokens
    if [[ $tokens -le 0 ]]; then
        # Release lock, wait, then retry
        rmdir "$lock_file" 2>/dev/null
        local wait_time=$((window / max_rate))
        log_warning "Rate limit hit for $source_name. Waiting ${wait_time}s..."
        sleep "$wait_time"
        acquire_token "$source_name" "$max_rate" "$window"
        return
    fi

    # Consume a token
    tokens=$((tokens - 1))
    echo "$tokens" > "$bucket_file"
    echo "$now" >> "$bucket_file"

    # Release lock
    rmdir "$lock_file" 2>/dev/null
}

# Clean up rate limiter state
cleanup_rate_limiter() {
    rm -rf "$RATE_LIMIT_DIR" 2>/dev/null
    log_info "Rate limiter state cleared."
}
