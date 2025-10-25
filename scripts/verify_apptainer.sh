#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMPOSE_CMD=${COMPOSE_CMD:-docker compose}
ARRAY_WIDTH=${ARRAY_WIDTH:-2}

source "$SCRIPT_DIR/lib/verify_common.sh"

JOB_SRC="$SCRIPT_DIR/../test_jobs"
JOB_DST="$SCRIPT_DIR/../shared"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --health          Run Slurm health checks (sinfo / scontrol).
  --build           Build or refresh Apptainer sandboxes.
  --sandbox         Submit sandbox job (/shared/apptainer_sbx.slurm).
  --oci             Submit OCI job (/shared/apptainer_smoke.slurm).
  --array           Submit Pillow array job (/shared/apptainer_array.slurm).
  --summary         Print /shared/out listing and job logs.
  --no-build        Skip sandbox builds (useful with --all).
  --all             Run health, build, sandbox, oci, array, and summary.
  --help            Show this message.

If no options are provided, --all is assumed.
EOF
}

DO_HEALTH=false
DO_BUILD=false
DO_SANDBOX=false
DO_OCI=false
DO_ARRAY=false
DO_SUMMARY=false
explicit_selection=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --health) DO_HEALTH=true; explicit_selection=true ;;
    --build) DO_BUILD=true; explicit_selection=true ;;
    --sandbox) DO_SANDBOX=true; explicit_selection=true ;;
    --oci) DO_OCI=true; explicit_selection=true ;;
    --array) DO_ARRAY=true; explicit_selection=true ;;
    --summary) DO_SUMMARY=true; explicit_selection=true ;;
    --no-build) DO_BUILD=false ;;
    --all)
      DO_HEALTH=true
      DO_BUILD=true
      DO_SANDBOX=true
      DO_OCI=true
      DO_ARRAY=true
      DO_SUMMARY=true
      explicit_selection=true
      ;;
    --help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if ! $explicit_selection; then
  DO_HEALTH=true
  DO_BUILD=true
  DO_SANDBOX=true
  DO_OCI=true
  DO_ARRAY=true
  DO_SUMMARY=true
fi

sync_test_jobs() {
  if [[ ! -d "$JOB_SRC" ]]; then
    echo "Job templates not found at $JOB_SRC" >&2
    exit 1
  fi
  mkdir -p "$JOB_DST"
  shopt -s nullglob
  for job in "$JOB_SRC"/*.slurm; do
    cp "$job" "$JOB_DST/"
  done
  shopt -u nullglob
}

ensure_shared_dirs() {
  compose_exec worker1 bash -lc 'mkdir -p /shared/out /shared/containers'
}

run_health_checks() {
  log "Cluster health"
  compose_exec controller sinfo
  compose_exec controller scontrol show nodes
}

build_sandboxes() {
  log "Build Alpine sandbox"
  compose_exec worker1 env APPTAINER_CAP_PATH=/etc/apptainer/capabilities-docker.conf \
    build-apptainer-sandbox alpine_sbx docker://alpine:3.19

  log "Build Python + Pillow sandbox"
  compose_exec worker1 env APPTAINER_CAP_PATH=/etc/apptainer/capabilities-docker.conf \
    build-apptainer-sandbox python311_pillow docker://python:3.11-slim

  log "Install Pillow into sandbox"
  compose_exec worker1 bash -lc \
    'export APPTAINER_CAP_PATH=/etc/apptainer/capabilities-docker.conf; apptainer exec --writable /shared/containers/python311_pillow pip install --no-cache-dir pillow'
}

run_sandbox_job() {
  log "Submit sandbox job"
  local job_id
  job_id=$(submit_job /shared/apptainer_sbx.slurm)
  wait_for_job "$job_id"
}

run_oci_job() {
  log "Submit OCI job"
  local job_id
  job_id=$(submit_job /shared/apptainer_smoke.slurm)
  wait_for_job "$job_id"
}

run_array_job() {
  log "Submit Pillow array job"
  local job_id
  job_id=$(submit_job /shared/apptainer_array.slurm)
  wait_for_array "$job_id" "$ARRAY_WIDTH"
}

print_summary() {
  log "Outputs"
  compose_exec controller bash -lc 'ls -l /shared/out'
  compose_exec controller bash -lc 'tail -n +1 /shared/out/*.out'
  log "PNG artifacts are under /shared/out/pillow"
}

sync_test_jobs
ensure_shared_dirs
$DO_HEALTH && run_health_checks
$DO_BUILD && build_sandboxes
$DO_SANDBOX && run_sandbox_job
$DO_OCI && run_oci_job
$DO_ARRAY && run_array_job
$DO_SUMMARY && print_summary
