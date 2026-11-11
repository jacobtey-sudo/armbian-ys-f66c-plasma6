# Известные проблемы

## CPU не масштабирует частоту

Симптомы в `dmesg`:

```text
cpu cpu0: failed to set opp config
cpu cpu0: failed to init opp info
cpufreq: regulator not ready, deferring initialization
cpufreq: gave up waiting for regulator after 50 retries
```

Фактически CPU работает на **816 МГц**, cpufreq/thermal-политики не поднялись.
Это главный известный кандидат на «тормознутость», важнее выбора файловой системы.
Нужно чинить regulator/OPP в DTS или порядке инициализации в vendor-ядре.

## Discover падает

Краш в Qt QML на Qt `6.8.2`; исправление в upstream Qt `6.8.4`, которого нет в
Debian trixie. Рабочий обход — Synaptic/apt. Не тянуть Qt/Plasma из sid.

## Виртуальная клавиатура

- Qt Virtual Keyboard на Qt 6.8/Wayland не работает client-side.
- Maliit даёт белый fullscreen-surface и отключён.
- Рабочий обход: Onboard + uinput, русская раскладка, автозапуск.
- Автопоказ по фокусу недоступен из-за отсутствующего Atspi typelib.

## microSD

Последовательное чтение около 16 МБ/с; для Plasma это заметно медленнее eMMC.
Swap должен быть на zram, не на microSD.

## PoE и питание

Не выдёргивать PoE без `shutdown`: уже было повреждение ext4 и переход rootfs в
read-only. После сбоя проверять `fsck`.
