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

chown_root_owned() {
	local root="$1" src="$2"
	( cd "$src" && find . -mindepth 1 -printf '%P\0' ) |
		while IFS= read -r -d '' rel; do
			if [[ -e "${root}/${rel}" || -L "${root}/${rel}" ]]; then
				chown -h root:root "${root}/${rel}"
			fi
		done
}

echo "[overlay] installing into /etc (mostly /etc/skel)"
cp -a "${OVERLAY}/etc/." /etc/
# The checkout is owned by the build user; system files must stay root-owned.
chown_root_owned /etc "${OVERLAY}/etc"

if [[ -d "${OVERLAY}/usr" ]]; then
	echo "[overlay] installing system applets and plugins"
	cp -a "${OVERLAY}/usr/." /usr/
	chown_root_owned /usr "${OVERLAY}/usr"
fi

# Refresh caches and enable the Bluetooth autoconnect service.
glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true
if [[ -f /usr/lib/systemd/system/ys-f66c-bt-autoconnect.service ]]; then
	systemctl enable ys-f66c-bt-autoconnect.service 2>/dev/null || true
fi

# The eMMC data partition is mounted by board support
# (ys-f66c-emmc-mount.service); make sure the unit has run.
if systemctl cat ys-f66c-emmc-mount.service >/dev/null 2>&1; then
	systemctl start ys-f66c-emmc-mount.service 2>/dev/null || true
fi

if [[ -n "${TARGET_USER}" ]]; then
	HOME_DIR="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
	if [[ -z "${HOME_DIR}" || ! -d "${HOME_DIR}" ]]; then
		echo "user not found or no home directory: ${TARGET_USER}" >&2
		exit 1
	fi
	echo "[overlay] installing into ${HOME_DIR}/.config"
	install -d -m 0755 "${HOME_DIR}/.config"
	cp -a "${OVERLAY}/etc/skel/.config/." "${HOME_DIR}/.config/"
	TARGET_GROUP="$(id -gn "${TARGET_USER}")"
	chown -R "${TARGET_USER}:${TARGET_GROUP}" "${HOME_DIR}/.config"
fi

echo "[overlay] done"
