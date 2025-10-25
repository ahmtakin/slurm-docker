#!/usr/bin/env bash
# Common helpers used by verification scripts.
set -euo pipefail

: "${COMPOSE_CMD:=docker compose}"

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

compose_exec() {
  local service=$1
  shift
  $COMPOSE_CMD exec -T "$service" "$@"
}

submit_job() {
  local script_path=$1
  local quoted
  quoted=$(printf '%q' "$script_path")
  compose_exec controller bash -lc "sbatch $quoted" | awk '{print $4}'
}

wait_for_job() {
  local job_id=$1
  local quoted_id
  quoted_id=$(printf '%q' "$job_id")
  while true; do
    local detail
    detail=$(compose_exec controller bash -lc "scontrol show job $quoted_id" 2>/dev/null || true)
    if [[ -z "$detail" ]]; then
      local state
      state=$(compose_exec controller bash -lc "sacct -j $quoted_id --format=State --parsable2 --noheader" 2>/dev/null | head -n1 | tr -d ' ')
      if [[ -n "$state" ]]; then
        log "Job $job_id -> $state"
        [[ "$state" == COMPLETED* ]] || return 1
        break
      fi
      log "Job $job_id no longer present; assuming finished."
      break
    fi
    local state
    state=$(grep -o 'JobState=[A-Z_]+' <<<"$detail" | head -n1 | cut -d= -f2)
    log "Job $job_id -> ${state:-UNKNOWN}"
    case "$state" in
      COMPLETED) break ;;
      FAILED|CANCELLED|TIMEOUT) return 1 ;;
    esac
    sleep 2
  done
}

wait_for_array() {
  local base_id=$1
  local width=${2:-1}
  for task in $(seq 1 "$width"); do
    wait_for_job "${base_id}_${task}"
  done
}
