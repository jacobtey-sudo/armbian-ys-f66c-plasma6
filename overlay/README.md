# Overlay

Файлы, которые попадают в образ как есть. `scripts/build.sh` копирует
`overlay/.` поверх board support, а `scripts/install-overlay.sh` ставит то же
самое на живую систему.

## Пользовательские настройки (`/etc/skel`)

- `.config/plasma-org.kde.plasma.desktop-appletsrc` — панель и апплеты:
  Application Dashboard, Window Buttons, Icons-only Task Manager, системные
  мониторы (CPU, RAM, диск/EMMC), Netspeed, Discover в списке запуска.
- `.config/kwinrc`, `kwinoutputconfig.json` — KWin: Wayland, поворот,
  отключённые эффекты, Maliit, DPMS.
- `.config/kdedefaults/` — дефолты KWin/Plasma для новых профилей.
- `.config/kglobalshortcutsrc`, `kxkbrc`, `plasma-localerc` — раскладки `ru,us`,
  локаль `ru_RU.UTF-8`.
- `.config/kaccessrc` — системный звонок выключен (пользовательский дефолт).
- `.config/plasmaparc` — звук изменения громкости выключен.
- `.config/bluedevilglobalrc` — Bluetooth; MAC-адреса — заглушки.
- `.config/gtk-3.0/`, `gtk-4.0/`, `gtkrc*` — оформление GTK под Breeze.
- `.config/powerdevilrc`, `powermanagementprofilesrc` — DPMS и питание.
- `.config/autostart/` — Yakuake; pasystray не запускается.
- Остальные `*-rc` — настройки Dolphin, Kate, Konsole, Gwenview, Kamoso,
  Spectacle, System Monitor и т. п.

## Системные настройки (`/etc`)

- `etc/xdg/kaccessrc` — системный звонок KDE выключен и защищён от
  переопределения: `[Bell][$i] SystemBell=false`.
- `etc/xdg/plasmaparc` — `[General] AudioFeedback=false`: plasma-pa не играет
  звук изменения громкости. OSD остаётся.
- `etc/environment.d/90-ys-f66c-qml-cache.conf` — `QML_DISABLE_DISK_CACHE=1`.
- `etc/systemd/user/plasma-*.service.d/10-ys-f66c.conf` — тот же обход для
  KWin и plasmashell, `mkdir /tmp/.X11-unix` для XWayland.
- `etc/wireplumber/wireplumber.conf.d/50-ys-f66c-bluetooth.conf` — отключает
  SBC-XQ, оставляя обычный SBC для стерео A2DP.

## Системные апплеты и плагины (`/usr`)

- `usr/share/plasma/plasmoids/org.kde.netspeedWidget/` — Netspeed 3.1.
- `usr/share/plasma/plasmoids/org.kde.windowbuttons/` — Window Buttons 0.14.0.
- `usr/lib/aarch64-linux-gnu/qt6/qml/org/kde/appletdecoration/` — плагин
  оформления Window Buttons (`libappletdecorationplugin.so`, arm64).
- `usr/lib/aarch64-linux-gnu/qt6/plugins/ksystemstats/ksystemstats_plugin_disk.so` —
  пропатченный плагин ksystemstats 6.3.4 для виджета EMMC; патч и инструкция —
  в [`patches/`](../patches/README.md).

## Maliit

- `usr/lib/aarch64-linux-gnu/maliit/keyboard2/qml/keys/LanguageMenu.qml` —
  пункт «Settings…» открывает `ys-osk:scale`.
- `usr/share/maliit/keyboard2/devices/ys-f66c-{small,medium,large}.json` —
  три профиля размера клавиатуры.
- `usr/share/glib-2.0/schemas/99-ys-f66c-maliit.gschema.override` — языки
  `en`, `ru`.
- `usr/local/bin/ys-f66c-osk-scale` +
  `usr/share/applications/ys-f66c-osk-scale.desktop` — выбор размера.
- `usr/local/bin/xdg-open` — снимает `QT_WAYLAND_SHELL_INTEGRATION` от Maliit
  (с ней Qt-программы падают), обрабатывает схему `ys-osk:`, остальные URL
  отдаёт `/usr/bin/xdg-open`.

## Bluetooth

- `usr/local/bin/ys-f66c-bt-autoconnect` — подключает доверенные
  аудиоустройства после загрузки.
- `usr/lib/systemd/system/ys-f66c-bt-autoconnect.service` — systemd-юнит;
  включается при установке overlay.

## Опциональные приложения

- `usr/local/bin/ys-f66c-install-flclash` — ставит FlClash (arm64) из
  зафиксированного релиза, SHA256 проверяется, `.deb` в git не хранится.
  `customize-image.sh` board support запускает скрипт при сборке образа.

## Установка на живую систему

```sh
sudo ./scripts/install-overlay.sh                 # только /etc/skel и /usr
sudo ./scripts/install-overlay.sh --user <имя>    # ещё и в ~<имя>/.config
```

Скрипт копирует файлы, выставляет `root:root` для системных путей и
включает `ys-f66c-bt-autoconnect.service`. Пользовательские настройки в
`~/.config` перезаписываются — делайте резервную копию.

## Не добавлять

- пароли, токены, SSH-ключи;
- машинно-зависимые hostname, serial и реальные MAC;
- абсолютные домашние пути конкретного пользователя;
- образы, `.deb`, архивы и логи.

Двоичные файлы (`*.so`) допустимы только как собранные из исходников
апплеты и плагины выше; источник, лицензия и способ пересборки — в
[`docs/third-party.md`](../docs/third-party.md) и
[`patches/README.md`](../patches/README.md).

---

[← Релизы](../docs/release.md) · [Оглавление](../README.md#документация) · [Patches →](../patches/README.md)
