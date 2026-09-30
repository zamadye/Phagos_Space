#!/usr/bin/env bash
# Reproducible Godot Standard + Web export-template installer for local Linux,
# headless sandbox, and CI-adjacent workflows. It never requires sudo.
set -euo pipefail

VERSION="${1:-4.3-stable}"
INSTALL_DIR="${GODOT_INSTALL_DIR:-$HOME/.local/bin}"
DATA_DIR="${GODOT_DATA_DIR:-$HOME/.local/share/godot}"
TEMPLATE_VERSION="${VERSION/-/.}"
TEMPLATE_DIR="$DATA_DIR/export_templates/$TEMPLATE_VERSION"
ARCH="$(uname -m)"

case "$ARCH" in
  x86_64|amd64)
    PLATFORM="linux.x86_64"
    ;;
  aarch64|arm64)
    PLATFORM="linux.arm64"
    ;;
  *)
    echo "Unsupported Linux architecture: $ARCH" >&2
    exit 65
    ;;
esac

for command in unzip; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command. Install it first (for Debian/Ubuntu: sudo apt install unzip)." >&2
    exit 127
  fi
done

fetch() {
  local url="$1"
  local destination="$2"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --retry 3 --output "$destination" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget --quiet --output-document="$destination" "$url"
  else
    echo "Install curl or wget to download Godot." >&2
    exit 127
  fi
}

binary_name="Godot_v${VERSION}_${PLATFORM}"
binary_path="$INSTALL_DIR/godot"
release_base="https://github.com/godotengine/godot/releases/download/$VERSION"
workspace="$(mktemp -d)"
trap 'rm -rf "$workspace"' EXIT

mkdir -p "$INSTALL_DIR" "$TEMPLATE_DIR"

if [[ ! -x "$binary_path" ]]; then
  echo "Downloading Godot $VERSION for $PLATFORM..."
  fetch "$release_base/$binary_name.zip" "$workspace/godot.zip"
  unzip -q "$workspace/godot.zip" -d "$workspace/godot"
  install -m 755 "$workspace/godot/$binary_name" "$binary_path"
else
  echo "Using existing Godot binary: $binary_path"
fi

if [[ ! -f "$TEMPLATE_DIR/web_release.zip" ]]; then
  echo "Downloading Godot $VERSION export templates..."
  fetch "$release_base/Godot_v${VERSION}_export_templates.tpz" "$workspace/templates.tpz"
  unzip -q "$workspace/templates.tpz" -d "$workspace/templates"
  # Godot's archive has a top-level templates/ directory.
  cp -a "$workspace/templates/templates/." "$TEMPLATE_DIR/"
else
  echo "Using existing export templates: $TEMPLATE_DIR"
fi

"$binary_path" --version
cat <<MESSAGE
Godot $VERSION is ready.

Use it in this shell:
  export PATH="$INSTALL_DIR:\$PATH"
  godot --headless --path . --editor --quit

Web export templates:
  $TEMPLATE_DIR
MESSAGE
