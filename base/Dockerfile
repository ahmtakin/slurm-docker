FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Enable 'universe' so slurm/munge are available
RUN apt-get update && \
    apt-get install -y --no-install-recommends runc \
      ca-certificates curl gnupg software-properties-common && \
    add-apt-repository -y universe && \
    add-apt-repository -y ppa:apptainer/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      slurm-wlm slurmd slurmctld munge tini \
      apptainer \
      fuse3 fuse-overlayfs squashfs-tools uidmap \
      tzdata \
      vim less procps && \
    rm -rf /var/lib/apt/lists/*

COPY apptainer.capabilities /etc/apptainer/capabilities-docker.conf
RUN set -eux; \
    sed -i "s|^[[:space:]]*#\?[[:space:]]*enable overlay *=.*|enable overlay = no|" /etc/apptainer/apptainer.conf; \
    sed -i "s|^[[:space:]]*#\?[[:space:]]*root default capabilities .*|root default capabilities = file|" /etc/apptainer/apptainer.conf || true; \
    if ! grep -q '^root default capabilities =' /etc/apptainer/apptainer.conf; then \
      printf '\nroot default capabilities = file\n' >> /etc/apptainer/apptainer.conf; \
    fi; \
    if grep -q '^root default capabilities file' /etc/apptainer/apptainer.conf; then \
      sed -i "s|^[[:space:]]*root default capabilities file .*|root default capabilities file = /etc/apptainer/capabilities-docker.conf|" /etc/apptainer/apptainer.conf; \
    else \
      printf 'root default capabilities file = /etc/apptainer/capabilities-docker.conf\n' >> /etc/apptainer/apptainer.conf; \
    fi; \
    sed -i "s|^[[:space:]]*#\?[[:space:]]*user default capabilities .*|user default capabilities = file|" /etc/apptainer/apptainer.conf || true; \
    if ! grep -q '^user default capabilities =' /etc/apptainer/apptainer.conf; then \
      printf '\nuser default capabilities = file\n' >> /etc/apptainer/apptainer.conf; \
    fi; \
    if grep -q '^user default capabilities file' /etc/apptainer/apptainer.conf; then \
      sed -i "s|^[[:space:]]*user default capabilities file .*|user default capabilities file = /etc/apptainer/capabilities-docker.conf|" /etc/apptainer/apptainer.conf; \
    else \
      printf 'user default capabilities file = /etc/apptainer/capabilities-docker.conf\n' >> /etc/apptainer/apptainer.conf; \
    fi

# Standard dirs & ownership
RUN mkdir -p /etc/slurm /var/spool/slurm /var/spool/slurmd /var/log/slurm /var/lib/munge && \
    chown -R slurm:slurm /var/spool/slurm /var/spool/slurmd /var/log/slurm && \
    chown -R munge:munge /etc/munge /var/lib/munge || true

ENV SLURM_LOG_DIR=/var/log/slurm
