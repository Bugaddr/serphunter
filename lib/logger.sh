#!/bin/bash

# lib/logger.sh - Structured Logging Framework
# Provides timestamped, leveled logging to both console and file

LOG_FILE=""
LOG_LEVEL=0  # 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR
LOG_FORMAT="[%s] [%-5s] %s\n"

declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
)

init_logger() {
    local log_dir="${1:-$OUTPUT_DIR}"
    LOG_FILE="${log_dir}/serphunter_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$log_dir"
    
    # Set log level based on runtime flags
    if [[ "${VERBOSE_MODE:-false}" == true ]]; then
        LOG_LEVEL=0  # DEBUG
    elif [[ "${QUIET_MODE:-false}" == true ]]; then
        LOG_LEVEL=3  # ERROR only
    else
        LOG_LEVEL=1  # INFO (default)
    fi
    
    # Write log header
    {
        echo "============================================"
        echo "SerphunterRecon Log"
        echo "Started: $(date --iso-8601=seconds)"
        echo "PID: $$"
        echo "Log Level: $LOG_LEVEL"
        echo "============================================"
    } > "$LOG_FILE"
}

_log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local level_num=${LOG_LEVELS[$level]:-0}
    
    # Check if this level should be logged
    [[ $level_num -lt $LOG_LEVEL ]] && return
    
    # Write to log file
    if [[ -n "$LOG_FILE" ]]; then
        printf "$LOG_FORMAT" "$timestamp" "$level" "$message" >> "$LOG_FILE"
    fi
    
    # Write to console with colors (respect quiet mode)
    if [[ "${QUIET_MODE:-false}" != true ]] || [[ "$level" == "ERROR" || "$level" == "WARN" ]]; then
        case "$level" in
            DEBUG) echo -e "${BLUE}[DEBUG]${NC} $message" ;;
            INFO)  echo -e "${GREEN}[INFO]${NC} $message" ;;
            WARN)  echo -e "${YELLOW}[WARN]${NC} $message" ;;
            ERROR) echo -e "${RED}[ERROR]${NC} $message" ;;
        esac
    fi
}

log_debug() { _log "DEBUG" "$@"; }

# Calculate and log execution metrics
log_metrics() {
    local operation=$1
    local start_time=$2
    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))
    
    _log "INFO" "METRIC: $operation completed in ${duration_ms}ms"
}

# Rotate log files (keep last 10)
rotate_logs() {
    local log_dir=$(dirname "$LOG_FILE")
    local count=$(ls -1 "$log_dir"/serphunter_*.log 2>/dev/null | wc -l)
    
    if [[ $count -gt 10 ]]; then
        ls -1t "$log_dir"/serphunter_*.log | tail -n +11 | xargs rm -f
        _log "INFO" "Rotated $((count - 10)) old log files"
    fi
}
