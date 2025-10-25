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
chown -R munge:munge /etc/munge /var/lib/munge /var/log/munge /run/munge || true
chmod 0700 /etc/munge /var/lib/munge /var/log/munge || true
chmod 0755 /run/munge || true
chmod 0400 /etc/munge/munge.key || true

munged --force -v
sleep 1

mkdir -p /var/spool/slurm
chown -R slurm:slurm /var/spool/slurm

exec slurmctld -Dvvv
