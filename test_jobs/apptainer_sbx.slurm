#!/bin/bash
#SBATCH -J sbx
#SBATCH -o /shared/out/sbx.%j.out

set -euo pipefail

export APPTAINER_CAP_PATH=/etc/apptainer/capabilities-docker.conf

CONTAINER=/shared/containers/alpine_sbx
if [ ! -d "$CONTAINER" ]; then
  echo "Missing sandbox at $CONTAINER (run build-apptainer-sandbox alpine_sbx docker://alpine:3.19)" >&2
  exit 1
fi

apptainer exec --bind /shared "$CONTAINER" \
  sh -lc 'echo "Host: $(hostname)"; cat /etc/os-release'
