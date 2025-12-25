#!/bin/bash

# lib/cache.sh - Local Disk Cache Layer
# Avoids redundant API calls by caching results with TTL

CACHE_DIR="data/cache"
CACHE_TTL=3600  # 1 hour default TTL in seconds

init_cache() {
    mkdir -p "$CACHE_DIR"
    log_info "Cache initialized at $CACHE_DIR (TTL: ${CACHE_TTL}s)"
}

# Generate a cache key from source + target
_cache_key() {
    local source=$1
    local target=$2
    echo "${source}_${target}" | md5sum | cut -d' ' -f1
}

# Check if a valid (non-expired) cache entry exists
cache_hit() {
    local source=$1
    local target=$2
    local key=$(_cache_key "$source" "$target")
    local cache_file="$CACHE_DIR/${key}.cache"
    local meta_file="$CACHE_DIR/${key}.meta"
    
    if [[ ! -f "$cache_file" || ! -f "$meta_file" ]]; then
        return 1
    fi
    
    # Check TTL
    local cached_at=$(cat "$meta_file" 2>/dev/null)
    local now=$(date +%s)
    local age=$((now - cached_at))
    
    if [[ $age -gt $CACHE_TTL ]]; then
        log_info "Cache expired for $source/$target (age: ${age}s)"
        return 1
    fi
    
    log_success "Cache hit for $source/$target (age: ${age}s)"
    return 0
}

# Read cached results
cache_get() {
    local source=$1
    local target=$2
    local key=$(_cache_key "$source" "$target")
    cat "$CACHE_DIR/${key}.cache" 2>/dev/null
}

# Write results to cache
cache_put() {
    local source=$1
    local target=$2
    local results_file=$3
    local key=$(_cache_key "$source" "$target")
    
    cp "$results_file" "$CACHE_DIR/${key}.cache"
    date +%s > "$CACHE_DIR/${key}.meta"
    
    local size=$(wc -l < "$results_file")
    log_info "Cached $size results for $source/$target"
}

# Invalidate cache for a specific source/target
cache_invalidate() {
    local source=$1
    local target=$2
    local key=$(_cache_key "$source" "$target")
    
    rm -f "$CACHE_DIR/${key}.cache" "$CACHE_DIR/${key}.meta"
    log_info "Cache invalidated for $source/$target"
}

# Purge all expired entries
cache_gc() {
    local purged=0
    local now=$(date +%s)
    
    for meta_file in "$CACHE_DIR"/*.meta; do
        [[ ! -f "$meta_file" ]] && continue
        
        local cached_at=$(cat "$meta_file")
        local age=$((now - cached_at))
        
        if [[ $age -gt $CACHE_TTL ]]; then
            local base="${meta_file%.meta}"
            rm -f "$base.cache" "$base.meta"
            ((purged++))
        fi
    done
    
    log_info "Cache GC: purged $purged expired entries"
}
