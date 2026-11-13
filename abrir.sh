#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
if [[ -f /.flatpak-info ]]; then
    exec flatpak-spawn --host "$PWD/breeze-editor" "$@"
fi
exec ./breeze-editor "$@"
