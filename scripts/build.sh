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

if [[ ! -d "${WORKDIR}/userpatches/.git" ]]; then
	log "cloning board support (userpatches) into ${WORKDIR}/userpatches"
	git clone "${ARMBIAN_BASE_REPO}" "${WORKDIR}/userpatches"
fi

log "pinning board support at ${ARMBIAN_BASE_COMMIT}"
git -C "${WORKDIR}/userpatches" fetch --all
git -C "${WORKDIR}/userpatches" checkout --detach "${ARMBIAN_BASE_COMMIT}"

log "applying Plasma 6 desktop overlay"
mkdir -p "${WORKDIR}/userpatches/overlay"
cp -a "${REPO_DIR}/overlay/." "${WORKDIR}/userpatches/overlay/"

log "running Armbian build (${BOARD_CONFIG})"
cd "${WORKDIR}"
./compile.sh "${BOARD_CONFIG}" build

log "done; see ${WORKDIR}/output/images"
