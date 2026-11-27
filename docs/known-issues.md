# Известные проблемы

## CPU regulator — исправлено

В DTS CPU-supply указывал на SYR827 по адресу `0x40`, а на плате стоит
TCS4525 по адресу `0x1c`. Из-за этого cpufreq не инициализировался и CPU
работал на 816 МГц.

Исправление в board support:

```dts
vdd_cpu: tcs4525@1c {
    compatible = "tcs,tcs452x";
    reg = <0x1c>;
};
```

После перезагрузки: `vdd_cpu` = 1025 мВ, CPU до 1608 МГц, governor
`schedutil`. Если снова появится 816 МГц — проверить
`dmesg | grep -E 'cpu cpu0|cpufreq|fan53555'`.

## TSADC — исправлено

Раньше `/sys/class/thermal` содержал только cooling devices, без
`thermal_zone*`: узел `tsadc@fe710000` был выключен, поэтому не было
штатного троттлинга.

В board support (коммит `b55b7e0`) добавлено:

```dts
&tsadc {
    status = "okay";
};
```

В образе `v26.11.0` работают зоны `soc-thermal` и `gpu-thermal`, датчики
`/sys/class/thermal/thermal_zone*/temp` (milli-°C) и троттлинг по
75/85 °C, critical — 115 °C. Это температура кристалла SoC, не корпуса
и не АКБ.

Проверка:

```sh
ls /sys/class/thermal/thermal_zone*
cat /sys/class/thermal/thermal_zone*/type
cat /sys/class/thermal/thermal_zone*/temp
sensors
```

Если зон нет — проверить, что загружен DTB из board support с `&tsadc`,
и посмотреть `dmesg | grep -i tsadc`.

## Поворот заставки Plymouth

Текстовая консоль повёрнута через `fbcon=rotate:1`, а вход SDDM — через
X11 `DisplayCommand`. Если Plymouth показывает графическую заставку, она
может остаться в портретной ориентации: у Plymouth нет общего поворота с
fbcon. Подробности и варианты — в [boot-rotation.md](boot-rotation.md).

## Qt QML: падение KWin, plasmashell и Discover (Qt 6.8.2)

Симптомы: `kwin_wayland` и `kwin_x11` падают с SIGSEGV примерно каждые
20 секунд, `plasmashell` и Discover тоже могут падать. В стеке видно
`QV4::CompiledData::CompilationUnit::loadFromDisk()` и `stringAtInternal()`
в `libQt6Qml.so.6`. Это не GPU/Mesa, не Maliit и не владельцы файлов.

Причина: Qt 6.8.2 проверяет размер и заголовок `.qmlc`, но читает таблицу
строк по внутренним смещениям до проверки целостности. Повреждённый или
устаревший файл в `~/.cache/<app>/qmlcache` приводит к SIGSEGV. Кэш — только
оптимизация запуска; без него QML компилируется при старте приложения.

Обход: `QML_DISABLE_DISK_CACHE=1` в systemd drop-in для KWin/plasmashell,
в `/etc/environment.d` и `/etc/environment` (входит в образ). После обхода
Wayland и X11 стабильны, новых core-дампов нет. Не тянуть Qt/Plasma из sid:
это потянет половину дистрибутива.

Upstream: исправление в более новых Qt (`6.8.4+`/`6.9`); в trixie только
6.8.2, поэтому обход остаётся до появления исправленного пакета.

## Экран блокировки и DPMS

После выключения экрана по DPMS панель просыпается с чёрным фоном и
цветными полосами. Board support отключает автоматическое выключение и
затемнение экрана в `/etc/xdg/powerdevilrc`. Восстановление без перезагрузки:

```sh
kscreen-doctor --dpms on
```

Пользовательский `~/.config/powerdevilrc` перекрывает системные настройки.

## Яркость подсветки

Вход подсветки панели active-low. Без флага `PWM_POLARITY_INVERTED`
ползунок яркости работает в обратную сторону. Флаг включён в DTS; нижний
уровень PWM снижен до `7/255`, чтобы минимальная яркость была темнее.

## Экранная клавиатура

- **Plasma (Wayland):** Maliit, языки en/ru, три профиля размера.
- **SDDM:** Qt Virtual Keyboard с отключённым QML-кэшем; Maliit в greeter не
  используется, потому что у SDDM нет Qt 6 input-context-плагина Maliit.

Автопоказ по фокусу не требуется: KWin сам поднимает Maliit для текстовых
полей. Onboard удалён.

## Bluetooth и наушники

- SBC-XQ на этом чипе не работает: звук пропадает. В образе он отключён
  (`/etc/wireplumber/wireplumber.conf.d/50-ys-f66c-bluetooth.conf`). Обычный
  SBC (A2DP) даёт стерео 48 кГц.
- Профиль HFP (`headset-head-unit`) даёт моно в обоих ушах — для микрофона,
  не для музыки.
- Перезапуск `wireplumber` при активном A2DP убирает профили A2DP до нового
  подключения.
- `ys-f66c-bt-autoconnect.service` подключает доверенные аудиоустройства
  после перезагрузки.

## eMMC и виджет EMMC

Раздел данных eMMC (`mmcblk0p15`) монтируется read-only в `/mnt/emmc`.
Сам раздел не изменяется. Стандартный `ksystemstats` исключает
flash-накопители, поэтому сенсор не появлялся. В образе установлен
пропатченный `ksystemstats_plugin_disk.so`; патч —
[`patches/ksystemstats-6.3.4-emmc.patch`](../patches/ksystemstats-6.3.4-emmc.patch).
Виджет «Использование EMMC» показывает занятое место этой файловой системы.

Если раздел пересоздан, UUID в `/etc/fstab` и настройках виджета нужно
обновить.

## microSD: скорость и надёжность

Последовательное чтение около 16 МБ/с; для Plasma это заметно медленнее
eMMC. Swap должен быть на zram, не на microSD.

Используйте брендовые карты (Samsung EVO Select/Plus, SanDisk Extreme/Ultra,
Kingston Canvas Go! Plus), Class 10/U3, A1/A2, от 16 ГБ: образ занимает
9,4 ГБ. No-name карты (например, с именем `asdfg`) могут молча портить
данные: файлы сохраняют размер и дату, но содержимое заменяется мусором.

Признаки:

- `dpkg -V` показывает `??5??????` у файлов, которые никто не менял;
- `ls`, `stat` или `md5sum` возвращают `Bad message`;
- в `dmesg`: `EXT4-fs error ... checksumming directory block` и
  `Remounting filesystem read-only`;
- после перезагрузки не загружается юнит, например
  `plasma-plasmashell.service: String is not UTF-8 clean`.

Проверить карту можно на другом компьютере, пока она не смонтирована:

```sh
sudo f3probe /dev/sdX
sudo badblocks -sv /dev/sdX
```

`e2fsck -f -y -D /dev/sdX1` ремонтирует файловую систему, но не устраняет
причину. Надёжнее сохранить данные и перепрошить проверенный образ на
новую карту. Если rootfs уже перешёл в read-only, система доживёт до
перезагрузки, но запись на карту невозможна.

## Обновление пакетов: apt, libcamera и ядро

`apt upgrade` (CLI `apt`) в trixie подтягивает новые зависимости для
`libcamera-ipa` и ставит `libcamera0.8`, `libpisp1`,
`libtensorflow-lite2.20.0`. `apt-get upgrade` такие пакеты оставляет
(kept back). В образе проверен libcamera 0.4.0; обновление до 0.8.0 камеру
не сломало (Kamoso работает), но это другой стек.

Чтобы обновить только безопасные пакеты без смены камерного стека:

```sh
sudo apt-get update
sudo apt-get upgrade
```

Ядро, U-Boot, `linux-image/dt/headers`, `armbian-bsp` и `armbian-firmware`
обычный upgrade не трогает — они остаются на версии образа. После
обновления glibc и kwin нужна перезагрузка. Не используйте
`apt full-upgrade`/`dist-upgrade` без необходимости.

## plasmashell: обрыв Wayland-соединения (Qt 6.8.2)

Иногда при работе с панелью (лаунчер, менеджер задач, смена окон)
`plasmashell` завершается с кодом 255:

```
xdg_surface#133: error 3: attached a buffer before configure event
The Wayland connection experienced a fatal error: протокол
```

KWin закрывает соединение из-за гонки в Qt 6.8.2 при создании
popup-поверхностей; это не GPU, не память и не диск. Upstream —
[KDE bug 507934](https://bugs.kde.org/show_bug.cgi?id=507934). В trixie
только Qt 6.8.2, исправление — в новых Qt.

`plasma-plasmashell.service` имеет `Restart=on-failure`, поэтому панель
поднимается сама за 1–2 секунды. Если падения станут частыми, как обход
можно попробовать software-рендер только для plasmashell
(`QT_QUICK_BACKEND=software`) или сессию Plasma X11. Тянуть Qt/Plasma из
sid не нужно.

## Долгая загрузка и чёрный экран с курсором — исправлено

В образе был включён `serial-getty@ttyFIQ0.service`, но устройства
`/dev/ttyFIQ0` на этой плате нет. Из-за `BindsTo=dev-ttyFIQ0.device` каждый
запуск ждал 90 секунд на `getty.target`; в это время на панели мог быть
чёрный экран с курсором, похожий на зависание. Board support отключает и
маскирует этот getty. UART2 (`ttyS2`) остаётся доступен.

После маскировки обычный `systemctl reboot` возвращает плату автоматически,
без нажатия кнопки; загрузка занимает около 28 секунд.

## PoE и питание

Не выдёргивать PoE без `shutdown`: уже было повреждение ext4 и переход
rootfs в read-only. После сбоя проверять `fsck`.

После `reboot` плата иногда не включается сама и требует повторной подачи
PoE или нажатия кнопки питания. Это отдельная проблема PMIC/питания; перед
выключением питания нужно дождаться полного завершения загрузки или
`shutdown`. Если проблема повторится, снимать журнал текущей загрузки и
проверять питание/PMIC отдельно.

---

[← Производительность](performance.md) · [Оглавление](../README.md#документация) · [Диагностика →](troubleshooting.md)
