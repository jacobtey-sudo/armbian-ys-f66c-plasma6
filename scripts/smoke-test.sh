#!/usr/bin/env bash
#
# Post-flash smoke test for the YS-F66C Plasma 6 image.
#
# Run on the tablet, preferably from a terminal inside Plasma:
#   ./scripts/smoke-test.sh
#
# The script does not change the system. It checks the board identity, boot
# media, failed units, rotation, audio, Bluetooth, camera, eMMC, thermal
# zones, CPU governor, storage and the running desktop session.
#
# Exit status: 0 — no errors, 1 — at least one error, 2 — warnings with
# --strict or wrong board without --force.

set -uo pipefail
shopt -s nullglob

FORCE=0
STRICT=0
TARGET_USER="${SUDO_USER:-$(id -un)}"
FAILED=0
WARNED=0
SKIPPED=0

usage() {
	cat <<'EOF'
usage: smoke-test.sh [--user NAME] [--strict] [--force]

  --user NAME  user whose desktop session to test (default: current/SUDO_USER)
  --strict     treat warnings as errors
  --force      run even if the board is not YS-F66C
EOF
}

while (($#)); do
	case "$1" in
		--user)
			[[ -n "${2:-}" ]] || { echo "--user needs a name" >&2; exit 2; }
			TARGET_USER="$2"
			shift 2
			;;
		--strict)
			STRICT=1
			shift
			;;
		--force)
			FORCE=1
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			echo "unknown argument: $1" >&2
			usage >&2
			exit 2
			;;
	esac
done

ok() { printf '[ OK ] %s\n' "$*"; }
fail() {
	printf '[FAIL] %s\n' "$*"
	FAILED=$((FAILED + 1))
}
warn() {
	printf '[WARN] %s\n' "$*"
	WARNED=$((WARNED + 1))
}
skip() {
	printf '[SKIP] %s\n' "$*"
	SKIPPED=$((SKIPPED + 1))
}
have() { command -v "$1" >/dev/null 2>&1; }

if [[ "${EUID}" -eq 0 && "${TARGET_USER}" == root ]]; then
	session_user="$(loginctl list-sessions --no-legend 2>/dev/null | awk 'NF >= 3 { print $3; exit }')"
	[[ -n "${session_user}" ]] && TARGET_USER="${session_user}"
fi

if ! id "${TARGET_USER}" >/dev/null 2>&1; then
	echo "user not found: ${TARGET_USER}" >&2
	exit 2
fi
if [[ "${EUID}" -ne 0 && "${TARGET_USER}" != "$(id -un)" ]]; then
	echo "only root can test another user's session" >&2
	exit 2
fi

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
TARGET_UID="$(id -u "${TARGET_USER}")"

run_as_user() {
	if [[ "${EUID}" -eq 0 && "${TARGET_USER}" != root ]]; then
		runuser -u "${TARGET_USER}" -- env \
			XDG_RUNTIME_DIR="/run/user/${TARGET_UID}" "$@"
	else
		"$@"
	fi
}

has_wayland() {
	compgen -G "/run/user/${TARGET_UID}/wayland-*" >/dev/null 2>&1
}

has_pipewire() {
	compgen -G "/run/user/${TARGET_UID}/pipewire-*" >/dev/null 2>&1
}

check_board() {
	local compatible model
	compatible="$(tr -d '\0' </proc/device-tree/compatible 2>/dev/null || true)"
	model="$(tr -d '\0' </proc/device-tree/model 2>/dev/null || true)"
	if [[ "${compatible}" == *"yisheng,ys-f66c"* ]]; then
		ok "плата: ${model:-Yisheng YS-F66C}"
	elif ((FORCE)); then
		warn "плата не YS-F66C (${model:-неизвестно}), проверка продолжена с --force"
	else
		fail "плата не YS-F66C (${model:-неизвестно}); используйте --force только осознанно"
	fi
}

check_kernel() {
	local kernel
	kernel="$(uname -r)"
	if [[ "${kernel}" == *vendor-rk35xx* ]]; then
		ok "ядро: ${kernel}"
	else
		fail "ядро не vendor-rk35xx: ${kernel}"
	fi
	if [[ -f /boot/dtb/rockchip/rk3566-ys-f66c.dtb ]]; then
		ok "DTB платы: /boot/dtb/rockchip/rk3566-ys-f66c.dtb"
	else
		fail "нет /boot/dtb/rockchip/rk3566-ys-f66c.dtb"
	fi
}

check_storage() {
	local root_src root_fs options media pct
	root_src="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
	root_fs="$(findmnt -n -o FSTYPE / 2>/dev/null || true)"
	options="$(findmnt -n -o OPTIONS / 2>/dev/null || true)"
	case "${root_src}" in
		/dev/mmcblk0*) media="eMMC" ;;
		/dev/mmcblk1*) media="microSD" ;;
		*) media="${root_src:-неизвестно}" ;;
	esac
	if [[ "${root_fs}" == ext4 ]]; then
		ok "корень: ${root_src} (${media}), ext4"
	else
		fail "корень не ext4: ${root_src} (${root_fs:-?})"
	fi
	if [[ ",${options}," == *,ro,* ]]; then
		fail "корень смонтирован read-only (${options})"
	else
		ok "корень смонтирован на запись"
	fi
	pct="$(df -P / 2>/dev/null | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')"
	if [[ "${pct}" =~ ^[0-9]+$ ]]; then
		if ((pct >= 95)); then
			fail "свободного места на / меньше 5% (занято ${pct}%)"
		elif ((pct >= 85)); then
			warn "свободного места на / меньше 15% (занято ${pct}%)"
		else
			ok "свободное место на /: занято ${pct}%"
		fi
	fi
}

check_failed_units() {
	local units unit
	if ! have systemctl; then
		fail "systemctl не найден"
		return
	fi
	units="$(systemctl --failed --no-legend --plain 2>/dev/null | awk 'NF { print $1 }')"
	if [[ -z "${units}" ]]; then
		ok "нет failed units"
		return
	fi
	fail "есть failed units:"
	while IFS= read -r unit; do
		printf '       %s\n' "${unit}"
	done <<<"${units}"
}

check_services() {
	local unit
	for unit in \
		ys-f66c-bt-unblock.service \
		ys-f66c-camera-rotate.service \
		ys-f66c-cpufreq-governor.service \
		ys-f66c-emmc-mount.service \
		ys-f66c-headset-route.service; do
		if systemctl is-enabled --quiet "${unit}" 2>/dev/null; then
			ok "включён: ${unit}"
		else
			fail "не включён: ${unit}"
		fi
	done
	if systemctl is-active --quiet sddm 2>/dev/null; then
		ok "SDDM активен"
	else
		fail "SDDM не активен"
	fi
}

check_rotation() {
	local rotate kwin
	if grep -qE '(^| )fbcon=rotate:1( |$)' /proc/cmdline; then
		ok "fbcon=rotate:1 в /proc/cmdline"
	else
		fail "в /proc/cmdline нет fbcon=rotate:1"
	fi
	rotate="$(cat /sys/class/graphics/fbcon/rotate 2>/dev/null || true)"
	if [[ "${rotate}" == 1 ]]; then
		ok "поворот fbcon: ${rotate}"
	else
		fail "поворот fbcon: ${rotate:-нет}"
	fi
	kwin="${TARGET_HOME}/.config/kwinoutputconfig.json"
	if [[ -f "${kwin}" ]]; then
		if grep -q 'Rotated270' "${kwin}"; then
			ok "KWin: Rotated270 в ${kwin}"
		else
			warn "в ${kwin} нет Rotated270"
		fi
	else
		warn "нет ${kwin}; KWin использует настройки по умолчанию"
	fi
	if have kscreen-doctor && has_wayland; then
		local out
		out="$(run_as_user kscreen-doctor -o 2>/dev/null || true)"
		if grep -qE 'Rotation: (1|3)' <<<"${out}"; then
			ok "KWin/kscreen: поворот 90°"
		else
			warn "kscreen-doctor не подтвердил поворот 90°"
		fi
	fi
}

check_audio() {
	if aplay -l 2>/dev/null | grep -qiE 'rk809|rk817'; then
		ok "звуковая карта rk809/rk817 найдена"
	else
		fail "в aplay -l нет rk809/rk817"
	fi
	if ! have wpctl; then
		skip "wpctl не найден"
		return
	fi
	if ! has_pipewire; then
		skip "нет сессии PipeWire; запустите тест из терминала Plasma"
		return
	fi
	if run_as_user wpctl inspect @DEFAULT_AUDIO_SINK@ >/dev/null 2>&1; then
		ok "PipeWire: sink по умолчанию есть"
	else
		fail "PipeWire: нет sink по умолчанию"
	fi
}

check_bluetooth() {
	local out
	if ! systemctl is-active --quiet bluetooth 2>/dev/null; then
		fail "служба bluetooth не активна"
		return
	fi
	ok "служба bluetooth активна"
	if ! have bluetoothctl; then
		fail "bluetoothctl не найден"
		return
	fi
	out="$(bluetoothctl show 2>&1 || true)"
	if grep -q '^Controller ' <<<"${out}"; then
		ok "Bluetooth-контроллер найден"
	else
		fail "Bluetooth-контроллер не найден"
	fi
	if grep -q 'Powered: yes' <<<"${out}"; then
		ok "Bluetooth включён"
	else
		warn "Bluetooth выключен (Powered: no)"
	fi
	if rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: yes'; then
		warn "Bluetooth заблокирован через rfkill"
	fi
}

check_camera() {
	if [[ -e /dev/video10 ]]; then
		ok "виртуальная камера /dev/video10 есть"
	else
		fail "нет /dev/video10"
	fi
	if systemctl is-active --quiet ys-f66c-camera-rotate 2>/dev/null; then
		ok "сервис поворота камеры активен"
	else
		fail "сервис ys-f66c-camera-rotate не активен"
	fi
	if have v4l2-ctl; then
		if v4l2-ctl --list-devices 2>/dev/null | grep -q 'video10'; then
			ok "v4l2-ctl видит video10"
		else
			fail "v4l2-ctl не видит video10"
		fi
	fi
}

check_emmc() {
	local size
	if [[ -b /dev/mmcblk0 ]]; then
		size="$(lsblk -dno SIZE /dev/mmcblk0 2>/dev/null | tr -d '[:space:]')"
		ok "eMMC: /dev/mmcblk0 (${size:-размер неизвестен})"
	else
		fail "нет /dev/mmcblk0 (eMMC)"
	fi
	if findmnt -n /mnt/emmc >/dev/null 2>&1; then
		ok "раздел данных eMMC смонтирован в /mnt/emmc"
	else
		warn "раздел данных eMMC не смонтирован; после установки на eMMC это нормально"
	fi
}

check_thermal() {
	local zones types zone type temp trips
	zones=(/sys/class/thermal/thermal_zone*)
	if ((${#zones[@]} == 0)); then
		fail "нет thermal_zone*"
		return
	fi
	types=()
	for zone in "${zones[@]}"; do
		type="$(cat "${zone}/type" 2>/dev/null || true)"
		temp="$(cat "${zone}/temp" 2>/dev/null || true)"
		types+=("${type}")
		if [[ "${temp}" =~ ^-?[0-9]+$ ]] && ((temp > -20000 && temp < 125000)); then
			ok "thermal ${type:-?}: $((temp / 1000)) °C"
		else
			fail "thermal ${type:-?}: недопустимая температура ${temp:-нет}"
		fi
	done
	if printf '%s\n' "${types[@]}" | grep -qx 'soc-thermal' &&
		printf '%s\n' "${types[@]}" | grep -qx 'gpu-thermal'; then
		ok "зоны soc-thermal и gpu-thermal есть"
	else
		warn "ожидались зоны soc-thermal и gpu-thermal"
	fi
	trips=(/sys/class/thermal/thermal_zone*/trip_point_*_temp)
	if ((${#trips[@]} >= 3)); then
		ok "trip points: ${#trips[@]}"
	else
		warn "trip points: ${#trips[@]} (ожидалось не меньше трёх)"
	fi
}

check_cpu() {
	local gov freq vdd state regulator
	gov="$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null || true)"
	if [[ "${gov}" == schedutil ]]; then
		ok "CPU governor: schedutil"
	else
		warn "CPU governor: ${gov:-нет} (ожидался schedutil)"
	fi
	freq="$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq 2>/dev/null || true)"
	[[ -n "${freq}" ]] && ok "текущая частота CPU: ${freq} кГц"
	vdd=""
	state=""
	for regulator in /sys/class/regulator/regulator.*; do
		[[ -r "${regulator}/name" ]] || continue
		if [[ "$(cat "${regulator}/name")" == vdd_cpu ]]; then
			vdd="$(cat "${regulator}/microvolts" 2>/dev/null || true)"
			state="$(cat "${regulator}/state" 2>/dev/null || true)"
			break
		fi
	done
	if [[ -n "${vdd}" ]]; then
		if [[ "${state}" == enabled ]] && ((vdd > 700000 && vdd < 1400000)); then
			ok "vdd_cpu: ${vdd} мкВ, ${state}"
		else
			warn "vdd_cpu: ${vdd} мкВ, ${state:-?}"
		fi
	else
		warn "регулятор vdd_cpu не найден"
	fi
}

check_network() {
	local links
	if ! have ip; then
		skip "ip не найден"
		return
	fi
	links="$(ip -brief link show 2>/dev/null | awk '{ print $1 }' |
		grep -E '^(eth|en|wlan|wl)' || true)"
	if [[ -n "${links}" ]]; then
		ok "сетевые интерфейсы: $(tr '\n' ' ' <<<"${links}")"
	else
		warn "не найдены eth/wlan интерфейсы"
	fi
	if rfkill list wlan 2>/dev/null | grep -q 'Soft blocked: yes'; then
		warn "Wi-Fi заблокирован через rfkill"
	fi
}

check_desktop() {
	if pgrep -x kwin_wayland >/dev/null 2>&1; then
		ok "KWin Wayland запущен"
	elif pgrep -x kwin_x11 >/dev/null 2>&1; then
		warn "запущен KWin X11, а не Wayland"
	else
		skip "графическая сессия не запущена; проверьте вход в Plasma"
	fi
	if pgrep -x plasmashell >/dev/null 2>&1; then
		ok "plasmashell запущен"
	else
		skip "plasmashell не запущен"
	fi
}

check_logs() {
	local errors=""
	if have dmesg; then
		errors="$(dmesg 2>/dev/null |
			grep -iE 'EXT4-fs error|I/O error|Remounting filesystem read-only' || true)"
	fi
	if [[ -z "${errors}" ]] && have journalctl; then
		errors="$(journalctl -k -b --no-pager 2>/dev/null |
			grep -iE 'EXT4-fs error|I/O error|Remounting filesystem read-only' || true)"
	fi
	if [[ -n "${errors}" ]]; then
		fail "в логе ядра есть ошибки ФС/ввода-вывода:"
		printf '%s\n' "${errors}" | sed 's/^/       /'
	elif have dmesg && dmesg >/dev/null 2>&1; then
		ok "в логе ядра нет ошибок ФС/ввода-вывода"
	else
		skip "нет доступа к dmesg/journalctl для проверки ошибок"
	fi
}

printf 'YS-F66C Plasma 6 smoke test\n'
printf 'пользователь: %s, хост: %s, дата: %s\n\n' \
	"${TARGET_USER}" "$(hostname)" "$(date -Iseconds)"

check_board
check_kernel
check_storage
check_failed_units
check_services
check_rotation
check_audio
check_bluetooth
check_camera
check_emmc
check_thermal
check_cpu
check_network
check_desktop
check_logs

printf '\nИтог: ошибок %d, предупреждений %d, пропусков %d\n' \
	"${FAILED}" "${WARNED}" "${SKIPPED}"

if ((FAILED > 0)); then
	exit 1
fi
if ((STRICT && WARNED > 0)); then
	exit 2
fi
exit 0
