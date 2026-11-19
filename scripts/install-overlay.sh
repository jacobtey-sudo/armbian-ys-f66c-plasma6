#!/usr/bin/env bash
#
# Install the Plasma 6 desktop overlay into a running YS-F66C system.
#
# By default the files go to /etc/skel so that new users inherit them.
# Pass --user NAME to also copy them into that user's ~/.config.
#
# Usage:
#   sudo ./scripts/install-overlay.sh
#   sudo ./scripts/install-overlay.sh --user jacob

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY="${REPO_DIR}/overlay"

TARGET_USER=""
while [[ $# -gt 0 ]]; do
	case "$1" in
		--user)
			TARGET_USER="${2:-}"
			shift 2
			;;
		-h | --help)
			echo "usage: $0 [--user NAME]"
			exit 0
			;;
		*)
			echo "unknown argument: $1" >&2
			exit 2
			;;
	esac
done

if [[ "${EUID}" -ne 0 ]]; then
	echo "run as root: sudo $0 $*" >&2
	exit 1
fi

if [[ ! -d "${OVERLAY}/etc" ]]; then
	echo "overlay not found: ${OVERLAY}/etc" >&2
	exit 1
fi

echo "[overlay] installing into /etc (mostly /etc/skel)"
cp -a "${OVERLAY}/etc/." /etc/
# The checkout is owned by the build user; system files must stay root-owned.
chown -R root:root /etc/skel /etc/environment.d /etc/systemd/user

if [[ -n "${TARGET_USER}" ]]; then
	HOME_DIR="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
	if [[ -z "${HOME_DIR}" || ! -d "${HOME_DIR}" ]]; then
		echo "user not found or no home directory: ${TARGET_USER}" >&2
		exit 1
	fi
	echo "[overlay] installing into ${HOME_DIR}/.config"
	install -d -m 0755 "${HOME_DIR}/.config"
	cp -a "${OVERLAY}/etc/skel/.config/." "${HOME_DIR}/.config/"
	chown -R "${TARGET_USER}:${TARGET_USER}" "${HOME_DIR}/.config"
fi

echo "[overlay] done"
