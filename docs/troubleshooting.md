# Диагностика

## С чего начать

```sh
systemctl --failed
journalctl -b -p err
dmesg --level=err,warn
plasmashell --version
uname -r
```

Полный отчёт для issue:

```sh
armbianmonitor -u
```

## Загрузка и экран

**Нет вывода вообще.** Подключите UART2 (1500000 8N1) и посмотрите, доходит ли
загрузчик до ядра. Если лог пуст — проверить питание, PoE и носитель. Если
ядро стартует, но экран чёрный — проверить `fbcon=rotate:1` в `/proc/cmdline`
и `dmesg | grep -i -E 'dsi|vop|panel'`.

**Неправильный поворот.** Значения для консоли, SDDM и KWin — в
[boot-rotation.md](boot-rotation.md). Быстрая проверка:

```sh
cat /sys/class/graphics/fbcon/rotate
grep -o 'fbcon=[^ ]*' /proc/cmdline
xrandr --query            # в сессии X11
```

**SDDM: чёрный экран или неверная ориентация.** Проверить
`/etc/sddm.conf.d/ys-f66c-rotation.conf` и
`/usr/local/sbin/ys-f66c-sddm-xsetup`; перезапустить SDDM:

```sh
sudo systemctl restart sddm
```

**Автологин.** Если он не нужен, уберите `User=` из
`/etc/sddm.conf.d/autologin.conf` и перезапустите SDDM.

## Plasma

**KWin/plasmashell падают циклически.** Проверить, что
`QML_DISABLE_DISK_CACHE=1` виден процессам:

```sh
systemctl --user show-environment | grep QML
tr '\0' '\n' </proc/$(pidof kwin_wayland)/environ | grep QML
```

Обход и причина — в [known-issues.md](known-issues.md). Не удаляйте
`~/.cache` «на всякий случай»: при отключённом кэше это не требуется.

**Панель пустая или пропали апплеты.** Проверить, что плазмоиды на месте:

```sh
ls /usr/share/plasma/plasmoids/org.kde.windowbuttons
ls /usr/share/plasma/plasmoids/org.kde.netspeedWidget
```

Перезапуск оболочки:

```sh
kquitapp6 plasmashell && kstart plasmashell
```

**Нет звука изменения громкости.** Так и задумано: `AudioFeedback=false`.
Если тик вернулся, пользователь включил его в настройках — системный файл
`/etc/xdg/plasmaparc` задаёт только дефолт и не является immutable.

**Звенит системный звонок.** Проверить:

```sh
kreadconfig6 --file /etc/xdg/kaccessrc --group Bell --key SystemBell
```

Должно быть `false`, группа помечена `[$i]`. Пользовательский
`~/.config/kaccessrc` не может переопределить immutable-значение.

## Экранная клавиатура

**Maliit не появляется.** Проверить настройки KWin:

```sh
kreadconfig6 --file ~/.config/kwinrc --group Wayland --key InputMethod
kreadconfig6 --file ~/.config/kwinrc --group Wayland --key VirtualKeyboardEnabled
```

Ожидается путь к `com.github.maliit.keyboard.desktop` и `true`. Языки и размер:

```sh
gsettings get org.maliit.keyboard.maliit enabled-languages
ys-f66c-osk-scale --help
```

**Клавиатура в SDDM.** Greeter использует Qt Virtual Keyboard; Maliit там не
работает. Если клавиатура мешает, поставить `InputMethod=none` в
`/etc/sddm.conf.d/ys-f66c-inputmethod.conf`.

## Звук

```sh
wpctl status
pactl list short sinks
pactl list short sources
systemctl --user status wireplumber
```

- **Наушники не глушат динамик** — проверить, что board support установил
  хук и что в `alsamixer` выбран правильный выход.
- **Bluetooth-стерео пропадает** — SBC-XQ отключён намеренно. Переключить
  профиль на A2DP/SBC:

  ```sh
  wpctl status
  wpctl set-profile <id> <profile>
  ```

- **Микрофон гарнитуры** — профиль HFP, моно. После переключения профиля
  звук может прерваться на секунду.

## Bluetooth

```sh
systemctl status bluetooth
bluetoothctl show
bluetoothctl devices
journalctl -u bluetooth -b
journalctl -u ys-f66c-bt-autoconnect -b
```

Если адаптер не найден — проверить ревизию платы (AP6212 или AIC8800D80) и
`dmesg | grep -i -E 'brcmfmac|aic|hci'`. Доверенные устройства подключает
`ys-f66c-bt-autoconnect.service`; после сопряжения устройство должно быть
`trusted`.

## Сеть

```sh
ip -br a
nmcli device status
dmesg | grep -i -E 'eth|stmmac|brcmfmac|aic8800'
```

Wi-Fi ревизии разные; если модуль не загрузился, смотреть точное имя
интерфейса и firmware в `dmesg`. Ethernet — IP101GR, DHCP по умолчанию.

## Камера

```sh
v4l2-ctl --list-devices
ls -l /dev/video10
```

Ожидается виртуальное устройство `/dev/video10` с повёрнутой картинкой.
Сырое UVC-устройство доступно только root — это нормально. Если `/dev/video10`
нет, проверить сервис камеры board support и `dmesg | grep -i uvc`.

## eMMC и виджет

```sh
findmnt /mnt/emmc
systemctl status ys-f66c-emmc-mount
lsblk -f
```

Раздел монтируется read-only. Если виджет показывает нули, проверьте, что
UUID в `/etc/fstab`/юните и в настройках виджета совпадает с текущим
(`lsblk -f`). Установка системы на eMMC заменяет разметку — см.
[flashing.md](flashing.md).

## Питание и зависания

- Не выдёргивать PoE без `shutdown`.
- После сбоя — `fsck` и проверка, что rootfs не перешёл в read-only:

  ```sh
  findmnt -no OPTIONS /
  dmesg | grep -i 'read-only'
  ```

- Если после `reboot` плата не включается, подать питание повторно и снять
  журнал текущей загрузки. Это отдельная проблема питания/PMIC, не Plasma.

## Обновление overlay без перепрошивки

```sh
sudo ./scripts/install-overlay.sh --user <имя>
sudo systemctl restart sddm
```

Скрипт копирует `/etc` и `/usr` из `overlay/`, выставляет root-владельца и
включает сервис автоподключения Bluetooth. Пользовательские настройки в
`~/.config` перезаписываются — делайте резервную копию.
