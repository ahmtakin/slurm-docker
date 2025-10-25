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

# Ownership & permissions as munge expects; bail out if macOS bind mount blocks fixes
if ! chown -R munge:munge /etc/munge /var/lib/munge /var/log/munge /run/munge; then
  echo "Failed to chown munge directories; make sure Docker Desktop is allowed to manage ownership for this bind mount." >&2
  exit 1
fi
chmod 0700 /etc/munge /var/lib/munge /var/log/munge
chmod 0755 /run/munge
chmod 0400 /etc/munge/munge.key

if [ ! -e /etc/localtime ]; then
  ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime || true
fi

mkdir -p /shared/.apptainer/cache /shared/containers /shared/out || true

export APPTAINER_CAP_PATH=/etc/apptainer/capabilities-docker.conf
export APPTAINER_EXPERIMENTAL=oci

munged --force -v
sleep 1

mkdir -p /var/spool/slurm
chown -R slurm:slurm /var/spool/slurm

exec slurmctld -Dvvv
