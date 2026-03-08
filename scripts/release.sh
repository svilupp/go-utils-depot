#!/usr/bin/env bash
set -euo pipefail

TOOL="${1:?Usage: release.sh <source-dir> <tool> <version>}"
VERSION="${2:?Usage: release.sh <source-dir> <tool> <version>}"
SOURCE_DIR=""

# If 3 args: release.sh <source-dir> <tool> <version>
# If 2 args: release.sh <tool> <version> (source-dir = ../<tool> relative to script)
if [ $# -eq 3 ]; then
  SOURCE_DIR="$(cd "$1" && pwd)"
  TOOL="$2"
  VERSION="$3"
elif [ $# -eq 2 ]; then
  TOOL="$1"
  VERSION="$2"
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  # Default: look for sibling repo directory ../../../<tool> (peer to go-utils-depot)
  SOURCE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)/${TOOL}"
fi

TAG="${TOOL}/${VERSION}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: source directory not found: $SOURCE_DIR"
  echo ""
  echo "Usage:"
  echo "  release.sh <tool> <version>              # looks for ../<tool>/ next to this repo"
  echo "  release.sh <source-dir> <tool> <version>  # explicit source path"
  exit 1
fi

DEPOT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${DEPOT_ROOT}/dist/${TOOL}_${VERSION}"
rm -rf "$DIST"
mkdir -p "$DIST"

COMMIT=$(git -C "$SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.buildTime=${BUILD_TIME}"

PLATFORMS=(
  "linux/amd64"
  "linux/arm64"
  "darwin/amd64"
  "darwin/arm64"
  "windows/amd64"
)

echo "Building ${TOOL} ${VERSION} (commit ${COMMIT}) from ${SOURCE_DIR}"
echo ""

for PLATFORM in "${PLATFORMS[@]}"; do
  GOOS="${PLATFORM%/*}"
  GOARCH="${PLATFORM#*/}"
  EXT=""
  [ "$GOOS" = "windows" ] && EXT=".exe"

  echo "  ${GOOS}/${GOARCH}"
  GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=0 \
    go build -C "$SOURCE_DIR" -trimpath -ldflags "$LDFLAGS" \
    -o "${DIST}/${TOOL}${EXT}" .

  ARCHIVE="${TOOL}_${VERSION}_${GOOS}_${GOARCH}"
  if [ "$GOOS" = "windows" ]; then
    (cd "$DIST" && zip -q "${ARCHIVE}.zip" "${TOOL}${EXT}" && rm "${TOOL}${EXT}")
  else
    (cd "$DIST" && tar czf "${ARCHIVE}.tar.gz" "${TOOL}${EXT}" && rm "${TOOL}${EXT}")
  fi
done

# Checksums
(cd "$DIST" && shasum -a 256 ${TOOL}_* > checksums.txt)

echo ""
echo "Archives:"
ls -lh "$DIST"
echo ""

echo "Creating release ${TAG}..."
cd "$DEPOT_ROOT"

gh release create "$TAG" "$DIST"/* \
  --repo svilupp/go-utils-depot \
  --title "${TOOL} ${VERSION}" \
  --notes "Release ${TOOL} ${VERSION}"

echo ""
echo "Done! Install with:"
echo "  eget svilupp/go-utils-depot --tag '${TOOL}/*' --to ~/.local/bin"
