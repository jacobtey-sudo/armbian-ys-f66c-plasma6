# Overlay

Файлы, которые кладутся в образ как есть.

`scripts/build.sh` копирует `overlay/.` поверх board support, а
`scripts/install-overlay.sh` ставит то же самое на живую систему.

## Десктоп-настройки (`/etc/skel`, `/etc`)

- `etc/skel/.config/kwinrc`, `kwinoutputconfig.json` — compositor, поворот, DPMS;
- `etc/skel/.config/kdedefaults/` — дефолты KWin/Plasma;
- `etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc` — панель и апплеты
  (Window Buttons, виджет EMMC с диаграммой, Discover вместо Synaptic);
- `etc/skel/.config/kglobalshortcutsrc`, `kxkbrc`, `plasma-localerc` — раскладки
  и локаль;
- `etc/skel/.config/bluedevilglobalrc` — Bluetooth (MAC-адреса — заглушки);
- `etc/skel/.config/gtk-3.0/`, `gtk-4.0/` — тема GTK;
- `etc/environment.d/90-ys-f66c-qml-cache.conf` — `QML_DISABLE_DISK_CACHE=1`;
- `etc/wireplumber/wireplumber.conf.d/50-ys-f66c-bluetooth.conf` — отключает
  нерабочий SBC-XQ (обычный SBC даёт стерео A2DP);
- прочие `*-rc` приложений KDE.

## Системные апплеты и плагины (`/usr`)

- `usr/share/plasma/plasmoids/` — Netspeed, Window Buttons;
- `usr/lib/aarch64-linux-gnu/qt6/plugins/ksystemstats/` — пропатченный
  `ksystemstats_plugin_disk.so` (виджет EMMC, см. `patches/`);
- `usr/lib/aarch64-linux-gnu/qt6/qml/org/kde/appletdecoration/` — плагин
  оформления (Window Buttons).

## Maliit, Bluetooth, размер клавиатуры

- `usr/lib/aarch64-linux-gnu/maliit/keyboard2/qml/keys/LanguageMenu.qml` —
  пункт «Settings…» открывает `ys-osk:scale`;
- `usr/share/maliit/keyboard2/devices/ys-f66c-{small,medium,large}.json` —
  профили размера клавиатуры;
- `usr/share/glib-2.0/schemas/99-ys-f66c-maliit.gschema.override` — языки `en`,`ru`;
- `usr/local/bin/ys-f66c-osk-scale` + `usr/share/applications/ys-f66c-osk-scale.desktop` —
  выбор размера;
- `usr/local/bin/ys-f66c-bt-autoconnect` +
  `usr/lib/systemd/system/ys-f66c-bt-autoconnect.service` — подключение
  доверенных аудиоустройств при загрузке.

## Не добавлять

- пароли, токены, SSH-ключи;
- машинно-зависимые hostname, serial и реальные MAC;
- абсолютные домашние пути конкретного пользователя.

Двоичные файлы (`*.so`) допустимы только как собранные из исходников апплеты и
плагины выше; патчи к ним лежат в `patches/`.
