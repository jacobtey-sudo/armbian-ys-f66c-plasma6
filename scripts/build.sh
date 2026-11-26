#!/usr/bin/env bash
#
# Build the YS-F66C Plasma 6 image.
#
# This repository is the desktop layer. Board support (DTS, U-Boot, kernel
# patches, board packages) lives in the public armbian-ys-f66c repository,
# pinned in config/versions.env. This script assembles both layers in a
# work tree and runs the Armbian build framework.
#
# Usage:
#   ./scripts/build.sh            # build into ./build
#   WORKDIR=~/ys-build ./scripts/build.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../config/versions.env
source "${REPO_DIR}/config/versions.env"

WORKDIR="${WORKDIR:-${REPO_DIR}/build}"
BOARD_CONFIG="${BOARD_CONFIG:-ys-f66c-trixie}"

log() { printf '[build] %s\n' "$*" >&2; }

: "${ARMBIAN_BUILD_REPO:?ARMBIAN_BUILD_REPO is not set in config/versions.env}"
: "${ARMBIAN_BUILD_COMMIT:?ARMBIAN_BUILD_COMMIT is not set in config/versions.env}"
: "${ARMBIAN_BASE_REPO:?ARMBIAN_BASE_REPO is not set in config/versions.env}"
: "${ARMBIAN_BASE_COMMIT:?ARMBIAN_BASE_COMMIT is not set in config/versions.env}"

mkdir -p "${WORKDIR}"

if [[ ! -d "${WORKDIR}/.git" ]]; then
	log "cloning Armbian build framework into ${WORKDIR}"
	git clone "${ARMBIAN_BUILD_REPO}" "${WORKDIR}"
fi

log "pinning Armbian build framework at ${ARMBIAN_BUILD_COMMIT}"
git -C "${WORKDIR}" fetch --all --tags
git -C "${WORKDIR}" checkout --detach "${ARMBIAN_BUILD_COMMIT}"

USERPATCHES="${WORKDIR}/userpatches"
OVERLAY_SRC="${REPO_DIR}/overlay"
OVERLAY_DST="${USERPATCHES}/overlay"
# Kept inside userpatches: the Armbian build checks its own tree for changes.
OVERLAY_MANIFEST="${USERPATCHES}/.ys-f66c-plasma6-overlay.list"

# Remove now-empty directories up to (but not including) the overlay root.
prune_empty_dirs() {
	local dir="$1"
	while [[ "${dir}" == "${OVERLAY_DST}/"* ]]; do
		rmdir "${dir}" 2>/dev/null || break
		dir="$(dirname "${dir}")"
	done
}

# Files copied by an earlier run must not linger after they leave the overlay.
# The board support repo tracks its own overlay content, so restore tracked
# files and delete only the untracked files this script added before.
clean_stale_overlay() {
	[[ -f "${OVERLAY_MANIFEST}" ]] || return 0
	log "removing stale overlay files from the previous run"
	while IFS= read -r rel; do
		[[ -n "${rel}" ]] || continue
		[[ -e "${OVERLAY_DST}/${rel}" || -L "${OVERLAY_DST}/${rel}" ]] || continue
		if git -C "${USERPATCHES}" ls-files --error-unmatch "overlay/${rel}" >/dev/null 2>&1; then
			git -C "${USERPATCHES}" checkout -- "overlay/${rel}"
		else
			rm -f "${OVERLAY_DST}/${rel}"
			prune_empty_dirs "$(dirname "${OVERLAY_DST}/${rel}")"
		fi
	done < "${OVERLAY_MANIFEST}"
	rm -f "${OVERLAY_MANIFEST}"
}

if [[ ! -d "${USERPATCHES}/.git" ]]; then
	log "cloning board support (userpatches) into ${USERPATCHES}"
	git clone "${ARMBIAN_BASE_REPO}" "${USERPATCHES}"
fi

log "pinning board support at ${ARMBIAN_BASE_COMMIT}"
git -C "${USERPATCHES}" fetch --all
# Drop the overlay copy from an earlier run so a pin change checks out cleanly.
git -C "${USERPATCHES}" checkout -- overlay 2>/dev/null || true
git -C "${USERPATCHES}" checkout --detach "${ARMBIAN_BASE_COMMIT}"

clean_stale_overlay

log "applying Plasma 6 desktop overlay"
[[ -d "${OVERLAY_SRC}" ]] || {
	echo "overlay not found: ${OVERLAY_SRC}" >&2
	exit 1
}
mkdir -p "${OVERLAY_DST}"
cp -a "${OVERLAY_SRC}/." "${OVERLAY_DST}/"
# Record what we copied, so the next run removes files that disappear.
(cd "${OVERLAY_SRC}" && find . -mindepth 1 ! -type d -printf '%P\n' | sort) > "${OVERLAY_MANIFEST}"

log "writing runtime pins (/etc/ys-f66c/versions.env)"
"${REPO_DIR}/scripts/gen-runtime-pins.sh" "${OVERLAY_DST}/etc/ys-f66c/versions.env"
# The generated file is ours too; clean it up if a later run stops writing it.
echo "etc/ys-f66c/versions.env" >> "${OVERLAY_MANIFEST}"

log "running Armbian build (${BOARD_CONFIG})"
cd "${WORKDIR}"
./compile.sh "${BOARD_CONFIG}" build

log "done; see ${WORKDIR}/output/images"
