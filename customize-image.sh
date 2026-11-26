#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# Image customization for the YS-F66C Plasma 6 desktop layer.

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	case $RELEASE in
		trixie)
			# Copy the desktop overlay (Plasma 6 settings, Maliit, SDDM)
			# collected from the validated running system.
			if [ -d /tmp/overlay ]; then
				# The checkout is owned by the build user; system files must stay root-owned.
				cp -a --no-preserve=ownership /tmp/overlay/. /
				# Rebuild the schema cache so overlay gschema overrides take effect.
				glib-compile-schemas /usr/share/glib-2.0/schemas || true
				# Register the ys-osk: handler used by the Maliit settings item.
				update-desktop-database /usr/share/applications || true
				# Connect trusted Bluetooth audio devices after boot.
				chmod 0755 /usr/local/bin/ys-f66c-bt-autoconnect || true
				systemctl enable ys-f66c-bt-autoconnect.service || true
				# Install the FlClash proxy client (arm64). Downloads a pinned .deb.
				if [ -x /usr/local/bin/ys-f66c-install-flclash ]; then
					/usr/local/bin/ys-f66c-install-flclash || echo "WARNING: FlClash install failed"
				fi
			fi
			# dpkg stops when a package file list has no final newline.
			# The trixie rootfs ships such a list (libpathplan4).
			for f in /var/lib/dpkg/info/*.list; do
				[ -n "$(tail -c 1 "$f")" ] && printf '\n' >> "$f"
			done
			# Mali-G52 Panfrost crashes Qt5 GL apps (Debian #1116427).
			# Mesa 25.2 fixes this. Backports provides it.
			apt-get update -qq || true
			apt-get install -y --no-install-recommends -t trixie-backports \
				libgl1-mesa-dri libegl-mesa0 libglx-mesa0 libgbm1 mesa-libgallium \
				mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers ||
				echo "WARNING: Mesa backports install failed"
			;;
		*)
			;;
	esac
} # Main

Main "$@"