
# Number of lines of log to be sent in slack alert.
export N_LOG_LINES=50

# Every X number of seconds to check the logs.
export CHECK_INTERVAL_SECS=60

# Number of seconds to sleep after sending alert, default is 24 hours to ensure channel isn't spammed.
export ALERT_TIMEOUT_SECS=$((24 * 60 * 60))

# Container names to monitor. Default value here is the list of names provided out of the box.
# Names can be viewed with command: `docker ps --format "{{.Names}}"`.
# Docker generates these names in a predictable way: <project_name>-<service_name>-<index>
#   - project_name = directory name where docker compose is running.
#   - service_name = taken from the service name specified in docker-compose.yml.
#   - index        = incrementing name starting at 1, increase if project is scaled.
export CONTAINER_NAMES="prover-node-docker-prover-node-1"
