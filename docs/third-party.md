# Сторонние компоненты

В overlay входят небольшие собранные апплеты и плагины. Их исходники,
лицензии и способ пересборки перечислены ниже. Файлы сохраняют свои
лицензии; репозиторий распространяется как GPL-2.0-only.

## Апплеты и плагины

### Netspeed Widget 3.1

- Автор: Daniel Faust.
- Лицензия: GPL-2.0-or-later.
- Исходники: <https://github.com/dfaust/plasma-applet-netspeed-widget>
- В overlay: `usr/share/plasma/plasmoids/org.kde.netspeedWidget/` (QML).
- Назначение: скорость сети в панели.

### Window Buttons 0.14.0

- Лицензия: GPL-2.0-or-later.
- Исходники: <https://github.com/moodyhunter/applet-window-buttons6>
- В overlay:
  - `usr/share/plasma/plasmoids/org.kde.windowbuttons/` (QML);
  - `usr/lib/aarch64-linux-gnu/qt6/qml/org/kde/appletdecoration/`
    (`libappletdecorationplugin.so`, `AuroraeButton.qml`, `qmldir`).
- Плагин собран под arm64 из upstream-версии 0.14.0.
- Назначение: кнопки окна в панели и оформление.

### ksystemstats 6.3.4 — патч для eMMC

- Лицензия: GPL-2.0-or-later.
- Исходники: <https://invent.kde.org/plasma/ksystemstats>
- Патч: [`patches/ksystemstats-6.3.4-emmc.patch`](../patches/ksystemstats-6.3.4-emmc.patch)
- В overlay: `usr/lib/aarch64-linux-gnu/qt6/plugins/ksystemstats/ksystemstats_plugin_disk.so`.
- Назначение: показывать раздел данных eMMC в виджете «Использование EMMC»
  (штатный фильтр скрывает flash-накопители) и заполнять сенсоры сразу.
- Пересборка: см. [patches/README.md](../patches/README.md).

## Приложения, устанавливаемые при сборке

### FlClash (arm64)

- Лицензия: GPL-3.0-or-later.
- Исходники: <https://github.com/chen08209/FlClash>
- Установщик: `usr/local/bin/ys-f66c-install-flclash`.
- Версия и SHA256 — в [`config/versions.env`](../config/versions.env);
  текущая версия — 0.9.4.
- `.deb` не хранится в git: скачивается из зафиксированного релиза,
  SHA256 проверяется. Если установка не удалась, сборка продолжается с
  предупреждением.

## Системные пакеты

Plasma, Qt, KDE Frameworks, SDDM, Maliit, WirePlumber и остальные
системные компоненты ставятся пакетами Debian 13 `trixie` и сохраняют
свои лицензии. Их версии фиксируются снимком дистрибутива, а не этим
репозиторием.

## Board support и сборочный фреймворк

- [armbian-ys-f66c](https://github.com/jacobtey-sudo/armbian-ys-f66c) —
  board support, GPL-2.0.
- [Armbian build](https://github.com/armbian/build) — GPL-2.0.

Оба подключаются на зафиксированных коммитах из
[`config/versions.env`](../config/versions.env).

---

[← Вопросы и ответы](faq.md) · [Оглавление](../README.md#документация) · [Релизы →](release.md)
