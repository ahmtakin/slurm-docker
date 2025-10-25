#!/bin/bash
#SBATCH -J pillow
#SBATCH --array=1-4
#SBATCH -o /shared/out/pillow.%A.%a.out

set -euo pipefail

export APPTAINER_CAP_PATH=/etc/apptainer/capabilities-docker.conf

CONTAINER=/shared/containers/python311_pillow
if [ ! -d "$CONTAINER" ]; then
  echo "Missing sandbox at $CONTAINER (run build-apptainer-sandbox python311_pillow docker://python:3.11-slim and install Pillow)." >&2
  exit 1
fi

IMG_DIR=/shared/out/pillow
mkdir -p "$IMG_DIR"

apptainer exec --bind /shared "$CONTAINER" python - <<'PY'
import os
from PIL import Image, ImageDraw

job_id = os.environ.get("SLURM_ARRAY_JOB_ID", "unknown")
task_id = os.environ.get("SLURM_ARRAY_TASK_ID", "0")
out_dir = "/shared/out/pillow"
os.makedirs(out_dir, exist_ok=True)
path = os.path.join(out_dir, f"tile_{job_id}_{task_id}.png")

img = Image.new("RGB", (160, 90), color=(30, 144, 255))
draw = ImageDraw.Draw(img)
draw.text((12, 34), f"job {job_id} task {task_id}", fill=(255, 255, 255))
img.save(path)
print(f"wrote {path}")
PY
