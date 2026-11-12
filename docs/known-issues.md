# Известные проблемы

## CPU regulator — исправлено

Причина была в DTS: CPU-supply указывал на SYR827 по адресу `0x40`, а на плате
стоит TCS4525 по адресу `0x1c`. Из-за этого cpufreq не инициализировался и CPU
работал на 816 МГц.

Исправление в `armbian-ys-f66c`:

```text
vdd_cpu: tcs4525@1c {
    compatible = "tcs,tcs452x";
    reg = <0x1c>;
```

После перезагрузки: `vdd_cpu` = 1025 мВ, CPU до 1608 МГц, governor `schedutil`.
Если снова появится 816 МГц — проверить `dmesg | grep -E 'cpu cpu0|cpufreq|fan53555'`.

## Нет thermal-зон

`/sys/class/thermal` содержит только cooling devices, без `thermal_zone*`.
CPU OPP ссылается на `soc-thermal`, но драйвер tsadc не регистрирует зоны.
Сейчас это не мешает работе, но означает отсутствие штатного thermal throttling.

## Поворот заставки Plymouth

Текстовая консоль повёрнута через `fbcon=rotate:1`, а вход SDDM — через
X11 `DisplayCommand`. Если Plymouth показывает графическую заставку, она может
остаться в портретной ориентации: у Plymouth нет общего поворота с fbcon.
Подробности и варианты — в [boot-rotation.md](boot-rotation.md).

## Discover падает

Краш в Qt QML на Qt `6.8.2`; исправление в upstream Qt `6.8.4`, которого нет в
Debian trixie. Рабочий обход — Synaptic/apt. Не тянуть Qt/Plasma из sid.

## Экран блокировки и DPMS

После выключения экрана по DPMS панель просыпается с чёрным фоном и цветными
полосами. BSP отключает автоматическое выключение и затемнение экрана в
`/etc/xdg/powerdevilrc`. Восстановление без перезагрузки:

```bash
kscreen-doctor --dpms on
```

Пользовательский `~/.config/powerdevilrc` перекрывает настройки BSP.

## Яркость подсветки

Вход подсветки панели active-low. Без флага `PWM_POLARITY_INVERTED` ползунок
яркости работает в обратную сторону. Флаг включён в `rk3566-ys-f66c.dts`.
Нижний уровень PWM снижен до `7/255`, чтобы минимальная яркость была темнее.

## Виртуальная клавиатура

- В сессии Plasma 6: Qt Virtual Keyboard на Qt 6.8/Wayland не работает
  client-side. Maliit даёт белый fullscreen-surface; пакеты Maliit удалены, а
  `[Wayland] InputMethod` убран из `kwinrc`. Рабочий обход — Onboard + uinput,
  русская раскладка, автозапуск.
- В SDDM-гретере штатная клавиатура SDDM/Breeze работает. Не задавайте
  `InputMethod` в конфиге SDDM: `qtvirtualkeyboard` зависает на Qt 6.8.2.
  xvkbd не устанавливать.
- Автопоказ Onboard по фокусу недоступен из-за отсутствующего Atspi typelib.

## microSD

Последовательное чтение около 16 МБ/с; для Plasma это заметно медленнее eMMC.
Swap должен быть на zram, не на microSD.

## PoE и питание

Не выдёргивать PoE без `shutdown`: уже было повреждение ext4 и переход rootfs в
read-only. После сбоя проверять `fsck`.
