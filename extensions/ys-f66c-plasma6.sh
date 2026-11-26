#!/usr/bin/env bash
#
# Desktop layer for the YS-F66C Plasma 6 image.
#
# The board support repository (armbian-ys-f66c) provides the hardware hooks
# and a console base. This extension adds the KDE, SDDM and Maliit pieces that
# only the desktop image needs.

# Desktop packages. The base board file keeps only the console tools.
function extension_prepare_config__ys_f66c_plasma6_packages() {
	display_alert "YS-F66C Plasma 6" "Adding desktop packages" "info"
	add_packages_to_image kamoso maliit-keyboard maliit-framework \
		libmaliit-plugins2 synaptic yakuake plasma-widgets-addons
}

# Power button (short press) opens the KDE logout / shutdown dialog, and the
# DSI panel must stay on: DPMS off/on corrupts it.
# SuspendSession::LogoutDialogMode == 16; key is powerButtonAction (lowercase)
# in the per-action group [<profile>][HandleButtonEvents].
function post_family_tweaks__ys_f66c_plasma6_powerdevil() {
	display_alert "$BOARD" "Configuring powerdevil (keep display on, power button dialog)" "info"
	local g
	for g in "${SDCARD}/etc/xdg/powerdevilrc" \
	         "${SDCARD}/etc/skel/.config/powerdevilrc"; do
		install -d -m 0755 "$(dirname "$g")"
		cat > "$g" <<-'EOT'
			[AC][Display]
			DimDisplayWhenIdle=false
			TurnOffDisplayWhenIdle=false

			[AC][HandleButtonEvents]
			powerButtonAction=16

			[Battery][Display]
			DimDisplayWhenIdle=false
			TurnOffDisplayWhenIdle=false

			[Battery][HandleButtonEvents]
			powerButtonAction=16

			[LowBattery][Display]
			DimDisplayWhenIdle=false
			TurnOffDisplayWhenIdle=false

			[LowBattery][HandleButtonEvents]
			powerButtonAction=16
		EOT
	done
}

# Holding Backspace at the start of a line makes the terminal/application ring
# the system bell for every key repeat. Each bell creates a new KWin audio
# stream; with A2DP active this stalls the compositor (thousands of "Key repeat
# discarded" messages) and loops the bell. The tablet has no need for an
# audible bell, so disable it system-wide, locked against user overrides, and
# for newly created users.
function post_family_tweaks__ys_f66c_plasma6_disable_bell() {
	display_alert "$BOARD" "Disabling the KDE system bell" "info"
	install -d -m 0755 "${SDCARD}/etc/xdg" "${SDCARD}/etc/skel/.config"

	# The [$i] suffix makes the group immutable: a leftover
	# ~/.config/kaccessrc with SystemBell=true cannot bring the loop back.
	cat > "${SDCARD}/etc/xdg/kaccessrc" <<-'EOT'
		[Bell][$i]
		SystemBell=false
	EOT
	cat > "${SDCARD}/etc/skel/.config/kaccessrc" <<-'EOT'
		[Bell]
		SystemBell=false
	EOT

	# plasma-pa plays the "audio-volume-change" event on every volume key
	# press, even when the volume is already at its limit. Holding the key at
	# 0 %/100 % turns that into a ticking loop (and a stalled A2DP stream).
	# The OSD already shows the volume, so turn the sound off.
	cat > "${SDCARD}/etc/xdg/plasmaparc" <<-'EOT'
		[General]
		AudioFeedback=false
	EOT
	cat > "${SDCARD}/etc/skel/.config/plasmaparc" <<-'EOT'
		[General]
		AudioFeedback=false
	EOT
}

# The SDDM greeter is X11. Rotate it before the greeter starts.
# The Plasma session is Wayland and keeps KWin's Rotated270 transform.
function post_family_tweaks_bsp__ys_f66c_plasma6_sddm_rotation() {
	display_alert "$BOARD" "Installing YS-F66C SDDM rotation hook" "info"
	install -d -m 0755 "${destination}/usr/local/sbin" "${destination}/etc/sddm.conf.d"
	cat > "${destination}/usr/local/sbin/ys-f66c-sddm-xsetup" <<-'EOT'
		#!/bin/sh
		# Rotate the greeter X server. Keep this idempotent.
		LOG=/var/log/ys-f66c-sddm-xsetup.log
		{
			echo "--- $(date '+%F %T') ---"
			echo "env DISPLAY=${DISPLAY:-} XAUTHORITY=${XAUTHORITY:-}"
		} >>"$LOG" 2>&1

		[ -n "${DISPLAY:-}" ] || DISPLAY=:0
		if [ -z "${XAUTHORITY:-}" ]; then
			XAUTHORITY=$(ls -t /run/sddm/xauth_* 2>/dev/null | head -1)
		fi
		export DISPLAY XAUTHORITY
		echo "use DISPLAY=$DISPLAY XAUTHORITY=${XAUTHORITY:-}" >>"$LOG" 2>&1
		command -v xrandr >/dev/null 2>&1 || exit 0

		# The connector can appear a moment after Xorg starts.
		i=0
		outputs=
		while [ "$i" -lt 25 ]; do
			outputs=$(xrandr --query 2>/dev/null | awk '/ connected/{print $1}')
			[ -n "$outputs" ] && break
			i=$((i + 1))
			sleep 0.2
		done
		echo "outputs: ${outputs:-none}" >>"$LOG" 2>&1
		for output in $outputs; do
			geometry=$(xrandr --query 2>/dev/null | awk -v out="$output" '$1 == out {print $3; exit}')
			case "$geometry" in
				*x*+*)
					width=${geometry%%x*}
					rest=${geometry#*x}
					height=${rest%%+*}
					if [ "${width:-0}" -lt "${height:-0}" ]; then
						echo "rotate $output right" >>"$LOG" 2>&1
						xrandr --output "$output" --rotate right >>"$LOG" 2>&1 || true
					fi
					;;
			esac
		done
	EOT
	chmod 0755 "${destination}/usr/local/sbin/ys-f66c-sddm-xsetup"
	cat > "${destination}/etc/sddm.conf.d/ys-f66c-rotation.conf" <<-'EOT'
		[General]
		DisplayServer=x11

		[X11]
		DisplayCommand=/usr/local/sbin/ys-f66c-sddm-xsetup
	EOT
}

# Touch input must match the greeter rotation. The greeter runs
# "xrandr --rotate right", so the touchscreen needs that matrix.
function post_family_tweaks_bsp__ys_f66c_plasma6_touch_rotation() {
	display_alert "$BOARD" "Installing YS-F66C touch rotation" "info"
	install -d -m 0755 "${destination}/etc/X11/xorg.conf.d"
	cat > "${destination}/etc/X11/xorg.conf.d/99-ys-f66c-touchscreen.conf" <<-'EOT'
		Section "InputClass"
		        Identifier "ys-f66c touchscreen rotation"
		        MatchIsTouchscreen "on"
		        Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"
		EndSection
	EOT
}

# SDDM greeter on-screen keyboard. Maliit has no Qt 6 input context plugin, so
# the Qt 6 greeter cannot use it. Use Qt Virtual Keyboard (Breeze style).
function post_family_tweaks_bsp__ys_f66c_plasma6_sddm_inputmethod() {
	display_alert "$BOARD" "Installing YS-F66C SDDM on-screen keyboard" "info"
	install -d -m 0755 "${destination}/etc/sddm.conf.d"
	cat > "${destination}/etc/sddm.conf.d/ys-f66c-inputmethod.conf" <<-'EOT'
		[General]
		InputMethod=qtvirtualkeyboard
		GreeterEnvironment=QML_DISABLE_DISK_CACHE=1
	EOT
}

# Qt 6.8.2 in trixie trusts the internal offsets of QML disk-cache files. A
# corrupted ~/.cache/*/qmlcache/*.qmlc makes KWin, plasmashell and Discover
# crash in QV4::CompiledData::CompilationUnit::loadFromDisk() / stringAtInternal().
# The cache is only a startup optimization, so disable it until Debian has a
# fixed Qt. Verified on hardware: KWin Wayland and X11 stayed up
# without new core dumps.
function post_family_tweaks__ys_f66c_plasma6_qml_cache() {
	display_alert "$BOARD" "Disabling QML disk cache (Qt 6.8.2 crash workaround)" "info"
	local envfile="${SDCARD}/etc/environment"
	touch "$envfile"
	if ! grep -q '^QML_DISABLE_DISK_CACHE=' "$envfile"; then
		printf '%s\n' 'QML_DISABLE_DISK_CACHE=1' >> "$envfile"
	fi
}

# The desktop overlay is checked out by a normal user. Make sure the files it
# installs into system paths do not stay owned by UID 1000 on the target.
# Run after customize-image.sh copies the overlay.
function post_customize_image__ys_f66c_plasma6_overlay_permissions() {
	display_alert "$BOARD" "Normalizing overlay file ownership" "info"
	chown root:root "${SDCARD}" "${SDCARD}/etc" 2>/dev/null || true
	for dir in \
		"${SDCARD}/etc/skel" \
		"${SDCARD}/etc/environment.d" \
		"${SDCARD}/etc/systemd/user" \
		"${SDCARD}/usr/share/plasma/plasmoids" \
		"${SDCARD}/usr/lib/aarch64-linux-gnu/qt6/qml/org/kde/appletdecoration" \
		"${SDCARD}/usr/lib/aarch64-linux-gnu/qt6/plugins/ksystemstats"; do
		if [ -d "$dir" ]; then
			chown -R root:root "$dir"
		fi
	done
}