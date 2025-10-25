#!/usr/bin/env bash
set -euo pipefail

# --- Ensure Munge dirs & key ---
# Copy key from host mount (Mac-friendly bind mount path)
mkdir -p /etc/munge
if [ -f /run/host/munge.key ]; then
  cp /run/host/munge.key /etc/munge/munge.key
fi

# Required runtime & log directories for munge
mkdir -p /run/munge /var/lib/munge /var/log/munge

# Ownership & permissions as munge expects
if ! chown -R munge:munge /etc/munge /var/lib/munge /var/log/munge /run/munge; then
  echo "Failed to chown munge directories; ensure Docker Desktop allows ownership changes on this mount." >&2
  exit 1
fi
chmod 0700 /etc/munge /var/lib/munge /var/log/munge
chmod 0755 /run/munge
chmod 0400 /etc/munge/munge.key

if [ ! -e /etc/localtime ]; then
  ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime || true
fi

mkdir -p /tmp/apptainer/tmp
chmod 1777 /tmp/apptainer /tmp/apptainer/tmp || true
mkdir -p /shared/.apptainer/cache /shared/containers /shared/out || true

export APPTAINER_CAP_PATH=/etc/apptainer/capabilities-docker.conf
export APPTAINER_EXPERIMENTAL=oci

munged --force -v
sleep 1
exec slurmd -Dvvv
