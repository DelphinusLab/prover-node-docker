#!/bin/bash

. .env

MAX_ALERT_TEXT_SIZE=4000
LOG_FILTER='s/\{/(/g; s/\}/)/g; s/\"//g'
DOCKER_INSPECT_FILTER='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}'

# Echo log with timestamp.
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Send alert to slack channel via curl.
send_alert() {
    post() {
        res=$(
            curl -X POST "$ALERT_POST_URL" \
                -H 'Content-type: application/json; charset=utf-8' \
                --data '{ "text": "'"$1"'" }'
        )
        if [ "$res" != "ok" ]; then
            log "Failed sending alert to url $ALERT_POST_URL"
        fi
    }

    message=$1
    info=$2
    logs=$3
    log "Sending alert to slack ... $message"

    log_chunks=()
    for ((i = 0; i < ${#logs}; i += MAX_ALERT_TEXT_SIZE)); do
        log_chunks+=("${logs:i:MAX_ALERT_TEXT_SIZE}")
    done

    post "$message"
    post "\`\`\`$info\`\`\`"
    for it in "${log_chunks[@]}"; do
        post "\`\`\`$it\`\`\`"
    done
}

# Gets startup info from logs of container and extracts node address, dryrun address, operating
# mode, and build version.
get_info_from_logs_and_format() {
    extract() {
        echo "$1" | grep "$2" | awk '{print $NF}'
    }

    container=$1
    logs=$(docker logs "$container" 2>/dev/null | head -n 70)
    node_addr=$(extract "$logs" "Node address")
    build_ver=$(extract "$logs" "Running build version")
    printf "Node Address: %s\\nDryRun Address: %s\\nOperating Mode: %s\\nBuild Version: %s\\n" \
        "$node_addr" "$build_ver"
}

# Check specified containers for healthy/running status; if neither, then send alert with recent logs.
check_container_status_and_alert() {
    containers=$CONTAINER_NAMES
    if [ "$containers" == "" ]; then
        log "Configuration error! No containers specified"
        exit 1
    fi

    for container in $containers; do
        status=$(docker inspect --format="$DOCKER_INSPECT_FILTER" "$container")
        if [ "$status" != "healthy" ] && [ "$status" != "running" ]; then
            message="\`$container\` crashed! Status is \`$status\`!"
            info=$(get_info_from_logs_and_format "$container" | sed -E "$LOG_FILTER")
            output=$(docker logs --tail "$N_LOG_LINES" "$container" | sed -E "$LOG_FILTER")
            return 1
        fi
    done
    return 0
}

# Main loop for checking status and sending alerts.
run_monitor() {
    while true; do
        log "Checking container statuses ..."
        if check_container_status_and_alert; then
            timeout=$CHECK_INTERVAL_SECS
        else
            send_alert "$message" "$info" "$output"
            timeout=$ALERT_TIMEOUT_SECS
        fi
        log "Sleeping for $timeout seconds"
        sleep "$timeout"
    done
}

log "Running docker prover monitor service"
run_monitor
