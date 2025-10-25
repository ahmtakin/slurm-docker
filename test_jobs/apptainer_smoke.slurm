#!/bin/bash
#SBATCH -J smoke
#SBATCH -o /shared/out/oci.%j.out

set -euo pipefail

export APPTAINER_CAP_PATH=/etc/apptainer/capabilities-docker.conf

if apptainer exec --help 2>&1 | grep -q -- '--oci'; then
  export APPTAINER_EXPERIMENTAL=oci
  apptainer exec --oci --bind /shared docker://alpine:3.19 \
    sh -lc 'echo "Host: $(hostname)"; cat /etc/os-release'
else
  echo "INFO: Apptainer $(apptainer --version) does not support --oci; using sandbox fallback." >&2
  apptainer exec --bind /shared /shared/containers/alpine_sbx \
    sh -lc 'echo "Host: $(hostname) (sandbox fallback)"; cat /etc/os-release'
fi
