#!/usr/bin/env bash
#
# Build the YS-F66C Plasma 6 image.
#
# This repository is the desktop layer. Board support (DTS, U-Boot, kernel
# patches, console base) lives in the public armbian-ys-f66c repository,
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
BOARD_CONFIG="${BOARD_CONFIG:-ys-f66c-plasma6}"

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
MANIFEST="${USERPATCHES}/.ys-f66c-plasma6-files.list"

BOARD_SRC="${REPO_DIR}/config/board/config-${BOARD_CONFIG}.conf"
BOARD_DST="${USERPATCHES}/config-${BOARD_CONFIG}.conf"
EXTENSION_SRC="${REPO_DIR}/extensions/ys-f66c-plasma6.sh"
EXTENSION_DST="${USERPATCHES}/extensions/ys-f66c-plasma6.sh"
CUSTOMIZE_SRC="${REPO_DIR}/customize-image.sh"
CUSTOMIZE_DST="${USERPATCHES}/customize-image.sh"
OVERLAY_SRC="${REPO_DIR}/overlay"
OVERLAY_DST="${USERPATCHES}/overlay"

# Remove now-empty directories up to (but not including) userpatches.
prune_empty_dirs() {
	local dir="$1"
	while [[ "${dir}" == "${USERPATCHES}/"* ]]; do
		rmdir "${dir}" 2>/dev/null || break
		dir="$(dirname "${dir}")"
	done
}

# Files copied by an earlier run must not linger after they leave this repo.
# Restore tracked board-support files and delete only the untracked files this
# script added before.
clean_stale_files() {
	[[ -f "${MANIFEST}" ]] || return 0
	log "removing files from the previous run"
	while IFS= read -r rel; do
		[[ -n "${rel}" ]] || continue
		[[ -e "${USERPATCHES}/${rel}" || -L "${USERPATCHES}/${rel}" ]] || continue
		if git -C "${USERPATCHES}" ls-files --error-unmatch "${rel}" >/dev/null 2>&1; then
			git -C "${USERPATCHES}" checkout -- "${rel}"
		else
			rm -f "${USERPATCHES}/${rel}"
			prune_empty_dirs "$(dirname "${USERPATCHES}/${rel}")"
		fi
	done < "${MANIFEST}"
	rm -f "${MANIFEST}"
}

if [[ ! -d "${USERPATCHES}/.git" ]]; then
	log "cloning board support (userpatches) into ${USERPATCHES}"
	git clone "${ARMBIAN_BASE_REPO}" "${USERPATCHES}"
fi

log "pinning board support at ${ARMBIAN_BASE_COMMIT}"
git -C "${USERPATCHES}" fetch --all
# Drop copies from an earlier run so a pin change checks out cleanly.
clean_stale_files
git -C "${USERPATCHES}" checkout -- . 2>/dev/null || true
rm -f "${USERPATCHES}/.ys-f66c-plasma6-overlay.list"
git -C "${USERPATCHES}" checkout --detach "${ARMBIAN_BASE_COMMIT}"

for src in "${BOARD_SRC}" "${EXTENSION_SRC}" "${CUSTOMIZE_SRC}"; do
	[[ -f "${src}" ]] || {
		echo "missing desktop layer file: ${src}" >&2
		exit 1
	}
done
[[ -d "${OVERLAY_SRC}" ]] || {
	echo "overlay not found: ${OVERLAY_SRC}" >&2
	exit 1
}

log "applying the Plasma 6 desktop layer"
install -D -m 0644 "${BOARD_SRC}" "${BOARD_DST}"
install -D -m 0644 "${EXTENSION_SRC}" "${EXTENSION_DST}"
install -D -m 0755 "${CUSTOMIZE_SRC}" "${CUSTOMIZE_DST}"
printf '%s\n' \
	"config-${BOARD_CONFIG}.conf" \
	"extensions/ys-f66c-plasma6.sh" \
	"customize-image.sh" > "${MANIFEST}"

# Board support ships no overlay; this repository owns the whole directory.
rm -rf "${OVERLAY_DST}"
mkdir -p "${OVERLAY_DST}"
cp -a "${OVERLAY_SRC}/." "${OVERLAY_DST}/"

log "writing runtime pins (/etc/ys-f66c/versions.env)"
"${REPO_DIR}/scripts/gen-runtime-pins.sh" "${OVERLAY_DST}/etc/ys-f66c/versions.env"

log "running Armbian build (${BOARD_CONFIG})"
cd "${WORKDIR}"
./compile.sh "${BOARD_CONFIG}" build

log "done; see ${WORKDIR}/output/images"