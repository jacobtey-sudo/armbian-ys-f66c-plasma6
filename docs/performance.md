# Производительность

## Что было узким местом

1. **CPU работал на 816 МГц.** В DTS был неверный CPU-regulator: SYR827 на
   `0x40` вместо TCS4525 на `0x1c`. Cpufreq не поднимался, OPP не
   инициализировался.
2. **microSD.** Последовательное чтение ~16 МБ/с, слабый random I/O.
3. **GPU не был виноват.** KWin использует OpenGL/Panfrost (`Mali-G52`),
   не `llvmpipe`.

## Что сделано

- DTS: `vdd_cpu` переведён на `tcs,tcs452x` по адресу `0x1c`.
- После перезагрузки: `vdd_cpu` 1025 мВ, CPU до **1608 МГц**.
- Governor: `schedutil` через `ys-f66c-cpufreq-governor.service`.
- Rootfs: ext4; swap — zram, не на накопитель.
- Эффекты KWin (blur, contrast, анимации) отключены в `kwinrc`.
- Дисковый QML-кэш отключён — это убирает падения Qt 6.8.2, но не скорость.

## Накопители

| Носитель | Последовательное чтение | Комментарий |
| --- | --- | --- |
| microSD | ~16 МБ/с | проверенный носитель образа |
| eMMC | ~163 МБ/с | HS200; быстрее, но требует установки системы |

Если система установлена на eMMC, Plasma работает заметно отзывчивее.
Раздел данных eMMC в текущей конфигурации смонтирован read-only и на
скорость не влияет.

## Проверка

```sh
cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq
for r in /sys/class/regulator/regulator.*; do
  [ "$(cat "$r/name")" = vdd_cpu ] && cat "$r/state" "$r/microvolts"
done
hdparm -tT /dev/mmcblk0
```

Ожидаемо: `schedutil`, частота до `1608000`, `vdd_cpu` enabled ~`1025000`
мкВ, eMMC заметно быстрее microSD.

## Осталось

- Нет `thermal_zone*`: штатного thermal throttling сейчас нет (см.
  [known-issues.md](known-issues.md#нет-thermal-зон--tsadc-выключен)).
- VOP2 пишет `_opp_set_regulators: no regulator (vop)`; на работу дисплея не
  влияет, но OPP дисплея не инициализируется.
- Discover/Qt 6.8.2 — отдельная известная проблема, не связана с CPU.
