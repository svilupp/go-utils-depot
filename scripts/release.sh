#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   release.sh <tool> <version>               # source dir resolved via registry, else derived
#   release.sh <source-dir> <tool> <version>  # explicit source path (always wins)
#
# Set RELEASE_DRAFT=1 to upload a draft for verification before publication.
#
# Examples:
#   ./scripts/release.sh newrelicexplorer v0.1.0
#   ./scripts/release.sh linear v0.4.2
#   ./scripts/release.sh /path/to/some-tool some-tool v1.0.0
#
# Resolve the scripts/ directory so all paths below are portable (no absolute /
# home paths committed). Everything is anchored to this.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Tool sources for this depot live under the go-training-range checkout, which
# sits next to go-utils-depot (both are siblings under a common parent). From
# scripts/ that is: up to the depot root (..), up once more to the common parent
# (..), then into go-training-range.
MONOREPO_ROOT="${SCRIPT_DIR}/../../go-training-range"

# Registry uses indexed arrays so the script also works with macOS Bash 3.2.
REGISTERED_TOOLS=(
  newrelicexplorer sentryexplorer openrouterexplorer linear logfire-trace
  logfire-viewer agent-playbooks slack argocdexplorer
)

TOOL="${1:?Usage: release.sh <tool> <version>  OR  release.sh <source-dir> <tool> <version>}"
VERSION="${2:?Usage: release.sh <tool> <version>  OR  release.sh <source-dir> <tool> <version>}"
SOURCE_DIR=""

# If 3 args: release.sh <source-dir> <tool> <version>
# If 2 args: release.sh <tool> <version> (source-dir from registry, else derived)
if [ $# -eq 3 ]; then
  SOURCE_DIR="$(cd "$1" && pwd)"
  TOOL="$2"
  VERSION="$3"
elif [ $# -eq 2 ]; then
  TOOL="$1"
  VERSION="$2"
  REGISTERED=""
  for CANDIDATE in "${REGISTERED_TOOLS[@]}"; do
    if [ "$CANDIDATE" = "$TOOL" ]; then
      REGISTERED="${MONOREPO_ROOT}/${TOOL}"
      break
    fi
  done
  if [ -n "$REGISTERED" ]; then
    SOURCE_DIR="$(cd "$REGISTERED" 2>/dev/null && pwd)" || {
      echo "Error: registered source directory for '${TOOL}' not found: ${REGISTERED}" >&2
      exit 1
    }
  else
    SOURCE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)/${TOOL}"
  fi
fi

TAG="${TOOL}/${VERSION}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: source directory not found: $SOURCE_DIR"
  echo ""
  echo "Usage:"
  echo "  release.sh <tool> <version>               # source dir from TOOL_SOURCES registry,"
  echo "                                            # else ../<tool>/ next to this repo"
  echo "  release.sh <source-dir> <tool> <version>  # explicit source path (always wins)"
  echo ""
  echo "Registered tools: ${REGISTERED_TOOLS[*]}"
  echo "Example: release.sh newrelicexplorer v0.1.0"
  exit 1
fi

DEPOT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${DEPOT_ROOT}/dist/${TOOL}_${VERSION}"
rm -rf "$DIST"
mkdir -p "$DIST"

COMMIT=$(git -C "$SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')
if [ "$TOOL" = "agent-playbooks" ]; then
  LDFLAGS="-s -w -X main.version=${VERSION}"
else
  LDFLAGS="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.buildTime=${BUILD_TIME}"
fi

PLATFORMS=(
  "linux/amd64"
  "linux/arm64"
  "darwin/amd64"
  "darwin/arm64"
  "windows/amd64"
)

echo "Building ${TOOL} ${VERSION} (commit ${COMMIT}) from ${SOURCE_DIR}"
echo ""

# Run pre-build hooks the source repo declares (e.g. logfire-viewer's `make
# assets` syncs //go:embed sources). Probe with `make -n` so tools without
# the target are silently skipped.
if [ -f "${SOURCE_DIR}/Makefile" ] && make -C "$SOURCE_DIR" -n assets >/dev/null 2>&1; then
  echo "Running 'make assets' in ${SOURCE_DIR}"
  make -C "$SOURCE_DIR" assets
  echo ""
fi

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
    # COPYFILE_DISABLE=1 suppresses macOS AppleDouble (._*) entries that
    # otherwise confuse extractors like eget into showing two candidates.
    (cd "$DIST" && COPYFILE_DISABLE=1 tar czf "${ARCHIVE}.tar.gz" "${TOOL}${EXT}" && rm "${TOOL}${EXT}")
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

RELEASE_ARGS=()
if [ "${RELEASE_DRAFT:-0}" = "1" ]; then
  RELEASE_ARGS+=(--draft)
fi

gh release create "$TAG" "$DIST"/* ${RELEASE_ARGS[@]+"${RELEASE_ARGS[@]}"} \
  --repo svilupp/go-utils-depot \
  --title "${TOOL} ${VERSION}" \
  --notes "Release ${TOOL} ${VERSION}"

echo ""
if [ "${RELEASE_DRAFT:-0}" = "1" ]; then
  echo "Draft uploaded. Verify its assets, then publish with gh release edit --draft=false."
else
  echo "Done! Install with:"
fi
echo "  eget svilupp/go-utils-depot --tag '${TOOL}/' --to ~/.local/bin"
