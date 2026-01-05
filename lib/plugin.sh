#!/bin/bash

# lib/plugin.sh - Dynamic Plugin Loader
# Discovers and loads enumeration modules at runtime
# Supports passive/active/all recon modes

PLUGIN_DIR=""
LOADED_PLUGINS=()

init_plugin_system() {
    PLUGIN_DIR="$SCRIPT_DIR/modules"
    
    if [[ ! -d "$PLUGIN_DIR" ]]; then
        log_error "Plugin directory not found: $PLUGIN_DIR"
        return 1
    fi
    
    log_info "Initializing plugin system (mode: ${RECON_MODE:-passive})"
    discover_plugins
}

# Discover plugins based on recon mode (passive/active/all)
discover_plugins() {
    local count=0
    local mode="${RECON_MODE:-passive}"
    local search_dirs=()
    
    # Determine which directories to scan
    case "$mode" in
        passive)
            search_dirs=("$PLUGIN_DIR/passive")
            ;;
        active)
            search_dirs=("$PLUGIN_DIR/active")
            ;;
        all)
            search_dirs=("$PLUGIN_DIR/passive" "$PLUGIN_DIR/active")
            ;;
        *)
            log_error "Unknown recon mode: $mode"
            return 1
            ;;
    esac
    
    for dir in "${search_dirs[@]}"; do
        [[ ! -d "$dir" ]] && continue
        local category=$(basename "$dir")

        for plugin_file in "$dir"/*.sh; do
            [[ ! -f "$plugin_file" ]] && continue
            
            local plugin_name=$(basename "$plugin_file" .sh)
            local func_name="run_${plugin_name}"
            
            # Apply --only filter: skip plugins not in the list
            if [[ -n "${ONLY_PLUGINS:-}" ]]; then
                if ! echo ",$ONLY_PLUGINS," | grep -q ",$plugin_name,"; then
                    log_debug "Skipping $plugin_name (not in --only list)"
                    continue
                fi
            fi
            
            # Apply --exclude filter: skip plugins in the list
            if [[ -n "${EXCLUDE_PLUGINS:-}" ]]; then
                if echo ",$EXCLUDE_PLUGINS," | grep -q ",$plugin_name,"; then
                    log_debug "Skipping $plugin_name (in --exclude list)"
                    continue
                fi
            fi
            
            # Validate plugin contract: must define run_<name>() function
            if grep -q "^${func_name}()" "$plugin_file" 2>/dev/null || \
               grep -q "^${func_name} ()" "$plugin_file" 2>/dev/null; then
                source "$plugin_file"
                LOADED_PLUGINS+=("$func_name")
                ((count++)) || true
                log_debug "Loaded [$category] $plugin_name"
            else
                log_warning "Skipping invalid plugin: $plugin_name (missing $func_name function)"
            fi
        done
    done
    
    log_success "Loaded $count plugins (${mode}): ${LOADED_PLUGINS[*]}"
}

# Execute all loaded plugins against a target
execute_plugins() {
    local target=$1
    local parallel=${2:-false}
    
    log_info "Executing ${#LOADED_PLUGINS[@]} plugins against $target..."
    
    # Dry-run mode: show what would run
    if [[ "${DRY_RUN:-false}" == true ]]; then
        for func in "${LOADED_PLUGINS[@]}"; do
            log_info "[DRY-RUN] Would execute: $func $target"
        done
        return 0
    fi
    
    for func in "${LOADED_PLUGINS[@]}"; do
        log_debug "Executing plugin: $func"
        if [[ "$parallel" == true ]]; then
            "$func" "$target" &
        else
            acquire_token "$(echo $func | sed 's/run_//')" # Rate limit each source
            "$func" "$target"
        fi
    done
    
    [[ "$parallel" == true ]] && wait
    log_success "All plugins completed."
}

# List available plugins with their status
list_plugins() {
    echo ""
    echo "Installed Plugins:"
    echo "==================="
    
    for category in passive active; do
        local cat_dir="$PLUGIN_DIR/$category"
        [[ ! -d "$cat_dir" ]] && continue
        
        echo ""
        echo "  [$category]"
        for plugin_file in "$cat_dir"/*.sh; do
            [[ ! -f "$plugin_file" ]] && continue
            local name=$(basename "$plugin_file" .sh)
            local func="run_${name}"
            
            if printf '%s\n' "${LOADED_PLUGINS[@]}" | grep -q "^${func}$" 2>/dev/null; then
                echo "    [✓] $name"
            else
                echo "    [ ] $name"
            fi
        done
    done
    echo ""
}
