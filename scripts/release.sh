#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   release.sh <tool> <version>               # source dir resolved via registry, else derived
#   release.sh <source-dir> <tool> <version>  # explicit source path (always wins)
#
# Set RELEASE_DRAFT=1 to upload a draft for verification before publication.
# Set RELEASE_BUILD_ONLY=1 to build archives and checksums without publishing.
#
# Examples:
#   ./scripts/release.sh newrelicexplorer v0.1.0
#   ./scripts/release.sh linear v0.4.2
#   ./scripts/release.sh /path/to/some-tool some-tool v1.0.0
#
# Resolve the scripts/ directory so all paths below are portable (no absolute /
# home paths committed). Everything is anchored to this.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source checkout locations are private local configuration. Override the root
# with RELEASE_SOURCE_ROOT or save one path in the ignored .release-source-root.
SOURCE_ROOT="${RELEASE_SOURCE_ROOT:-}"
if [ $# -eq 2 ] && [ -z "$SOURCE_ROOT" ] && [ -f "${SCRIPT_DIR}/../.release-source-root" ]; then
  IFS= read -r SOURCE_ROOT < "${SCRIPT_DIR}/../.release-source-root" || [ -n "$SOURCE_ROOT" ]
fi

# Registered tools use subdirectories of the configured source root. Keep an
# indexed array so the script works with macOS Bash 3.2.
REGISTERED_TOOLS=(
  sotto notion wipd newrelicexplorer sentryexplorer openrouterexplorer linear logfire-trace
  logfire-viewer agent-playbooks slack argocdexplorer
  lightdashctl dbexplorer firestoreexplorer agenticforge revlet
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
    if [ "$CANDIDATE" = "$TOOL" ] && [ -n "$SOURCE_ROOT" ]; then
      REGISTERED="${SOURCE_ROOT}/${TOOL}"
      break
    fi
  done
  if [ -n "$REGISTERED" ]; then
    # Resolve the registered source path to a clean absolute path so downstream
    # `go build -C` works from any working directory.
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
  echo "  release.sh <tool> <version>               # source dir from registry,"
  echo "                                            # else ../<tool>/ next to this repo"
  echo "  release.sh <source-dir> <tool> <version>  # explicit source path (always wins)"
  echo ""
  echo "Registered tools: ${REGISTERED_TOOLS[*]}"
  echo "Set RELEASE_SOURCE_ROOT=/path/to/sources or pass an explicit source directory."
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

# lightdashctl's bundle lock and dbexplorer's activity log use Unix file
# locking. Keep both releases usable on supported targets until the source
# modules add Windows implementations.
if [ "$TOOL" = "lightdashctl" ] || [ "$TOOL" = "dbexplorer" ]; then
  PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
  )
fi

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
    go build -C "$SOURCE_DIR" -trimpath -buildvcs=false -ldflags "$LDFLAGS" \
    -o "${DIST}/${TOOL}${EXT}" .

  ARCHIVE="${TOOL}_${VERSION}_${GOOS}_${GOARCH}"
  PACKAGE_DIR="$DIST"
  PACKAGE_FILES=("${TOOL}${EXT}")
  if [ "$TOOL" = "revlet" ]; then
    PACKAGE_DIR="${DIST}/.revlet-package"
    mkdir -p "$PACKAGE_DIR"
    mv "${DIST}/${TOOL}${EXT}" "$PACKAGE_DIR/"
    python3 "${SCRIPT_DIR}/package-revlet.py" "$SOURCE_DIR" "$DEPOT_ROOT" "$PACKAGE_DIR"
    PACKAGE_FILES+=(README.md CHANGELOG.md revlet.example.toml LICENSE TAILWIND-LICENSE MERMAID-LICENSE docs browser pi scripts)
  fi
  if [ "$GOOS" = "windows" ]; then
    # -X omits extra fields, including local Unix ownership metadata.
    (cd "$PACKAGE_DIR" && zip -q -X -r "${DIST}/${ARCHIVE}.zip" "${PACKAGE_FILES[@]}" && rm "${TOOL}${EXT}")
  else
    # Keep local user/group names out of archive headers. GNU and BSD tar
    # use different ownership flags. COPYFILE_DISABLE suppresses AppleDouble.
    if tar --version 2>/dev/null | grep -q 'GNU tar'; then
      (cd "$PACKAGE_DIR" && COPYFILE_DISABLE=1 tar --format=ustar --no-xattrs --owner=0 --group=0 --numeric-owner -czf "${DIST}/${ARCHIVE}.tar.gz" "${PACKAGE_FILES[@]}" && rm "${TOOL}${EXT}")
    else
      (cd "$PACKAGE_DIR" && COPYFILE_DISABLE=1 tar --format=ustar --no-xattrs --uid 0 --gid 0 --uname root --gname root -czf "${DIST}/${ARCHIVE}.tar.gz" "${PACKAGE_FILES[@]}" && rm "${TOOL}${EXT}")
    fi
  fi
  if [ "$TOOL" = "revlet" ]; then
    rm -rf "$PACKAGE_DIR"
  fi
done

# Checksums
(cd "$DIST" && shasum -a 256 ${TOOL}_* > checksums.txt)

echo ""
echo "Archives:"
ls -lh "$DIST"
echo ""

if [ "${RELEASE_BUILD_ONLY:-0}" = "1" ]; then
  echo "Build-only complete for ${TAG}. No GitHub release created."
  exit 0
fi

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
echo "  eget svilupp/go-utils-depot --tag '${TAG}' --to ~/.local/bin"
