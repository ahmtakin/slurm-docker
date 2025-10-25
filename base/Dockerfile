FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Enable 'universe' so slurm/munge are available
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y universe && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      slurm-wlm slurmd slurmctld munge tini ca-certificates \
      vim less procps && \
    rm -rf /var/lib/apt/lists/*

# Standard dirs & ownership
RUN mkdir -p /etc/slurm /var/spool/slurm /var/spool/slurmd /var/log/slurm /var/lib/munge && \
    chown -R slurm:slurm /var/spool/slurm /var/spool/slurmd /var/log/slurm && \
    chown -R munge:munge /etc/munge /var/lib/munge || true

ENV SLURM_LOG_DIR=/var/log/slurm
