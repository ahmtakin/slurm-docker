#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: build-apptainer-sandbox <sandbox-name> <source-uri>" >&2
  exit 1
fi

NAME="$1"
SOURCE="$2"
TMP_ROOT="$(mktemp -d /tmp/apptainer-build-XXXXXX)"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p /tmp/apptainer/tmp

echo "[build-apptainer-sandbox] building ${NAME} from ${SOURCE}"
apptainer build --fix-perms --sandbox "${TMP_ROOT}/${NAME}" "$SOURCE"

TARGET_DIR="/shared/containers"
mkdir -p "$TARGET_DIR"

if [ -e "${TARGET_DIR}/${NAME}" ]; then
  echo "[build-apptainer-sandbox] removing existing ${TARGET_DIR}/${NAME}"
  rm -rf "${TARGET_DIR:?}/${NAME}"
fi

echo "[build-apptainer-sandbox] copying sandbox into ${TARGET_DIR}"
tar -C "$TMP_ROOT" -cf - "$NAME" | tar -C "$TARGET_DIR" -xpf - --no-same-owner --no-same-permissions

echo "[build-apptainer-sandbox] completed ${NAME}"
