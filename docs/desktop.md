# Рабочий стол

Образ ставит KDE Plasma 6.3.6 с сессией Wayland (KWin) и входом через SDDM.
Пользователь создаётся при первом запуске; предсозданных учётных записей нет.

## Панель

- **Верхняя панель:** Application Dashboard, меню приложений, цифровые часы,
  Window Buttons, системный лоток.
- **Нижняя панель:** Icons-only Task Manager, системные мониторы (CPU, RAM,
  диск/EMMC), Netspeed.
- **Оформление окна:** кнопки `XIAH` слева и `S` справа; Window Buttons
  собран под arm64.
- **Эффекты:** blur, contrast, wobbly windows, slide, fading popups и
  magic lamp выключены для производительности.
- **Экран:** DPMS-выключение и затемнение отключены; панель не уходит в
  чёрный экран с артефактами.

## Локаль, раскладки, клавиатура

- Локаль `ru_RU.UTF-8`, язык интерфейса — русский.
- Раскладки `ru,us`.
- **Maliit** — экранная клавиатура Plasma: языки en/ru, три профиля размера
  (small/medium/large). Пункт «Settings…» в меню языка открывает
  `ys-osk:scale` — выбор размера; схему обрабатывает `/usr/local/bin/xdg-open`.
- **SDDM** (X11-гретер) использует Qt Virtual Keyboard; QML-кэш для greeter
  отключён. Maliit в SDDM не используется: у greeter нет Qt 6
  input-context-плагина Maliit.

## Звук

- Устройства и громкость — штатный Plasma PA; OSD громкости работает.
- **Звук изменения громкости отключён** (`AudioFeedback=false`): удержание
  клавиш громкости на пределе не создаёт очередь звуковых потоков.
- **Системный звонок KDE выключен** и защищён от переопределения
  (`/etc/xdg/kaccessrc`, группа `[Bell][$i]`): Backspace в пустом поле и
  другие «ошибочные» события не звенят.
- Проводные наушники глушат динамик (хук board support).
- Bluetooth: A2DP (SBC) для стерео, HFP (`headset-head-unit`) — моно для
  микрофона. SBC-XQ отключён.
- `ys-f66c-bt-autoconnect.service` подключает доверенные аудиоустройства
  после загрузки.

## Питание

- Кнопка питания открывает меню завершения работы KDE.
- Swap — zram, не на microSD/eMMC.
- Питание PoE: выключать только через `shutdown`.

## eMMC

Раздел данных eMMC монтируется только для чтения в `/mnt/emmc` (это делает
board support) и показывается виджетом «Использование EMMC». Сам раздел не
изменяется.

Виджет настроен на UUID файловой системы раздела (сенсоры
`disk/<UUID>/...`). Если раздел пересоздан или разметка другая, обновите
UUID в `/etc/fstab` и в настройках виджета. Установка системы на eMMC
заменяет разметку и удаляет раздел данных — см. [flashing.md](flashing.md).

## Стабильность Qt 6.8.2

Дисковый QML-кэш отключён (`QML_DISABLE_DISK_CACHE=1`) в
`/etc/environment.d`, `/etc/environment` и systemd-drop-in для KWin и
plasmashell. Это обход падения `QV4::CompiledData::CompilationUnit::loadFromDisk()`
в Qt 6.8.2; подробности — в [known-issues.md](known-issues.md).

## Приложения

- **Discover** — установка и обновление приложений.
- **Yakuake** — выпадающий терминал (автозапуск).
- **Dolphin**, **Kate**, **Konsole**, **Gwenview**, **System Monitor**,
  **Spectacle**, **Partitionmanager**, **Kamoso** (камера настроена на
  `/dev/video10`; нужна Mesa из `trixie-backports`, см. `troubleshooting.md`).
- **Firefox ESR** — браузер.
- **KDE Connect** — интеграция с телефоном.
- **FlClash** (arm64) — прокси-клиент; ставится при сборке из
  зафиксированного релиза, SHA256 проверяется. Если загрузка при сборке не
  удалась, образ собирается с предупреждением, а установщик можно запустить
  позже: `sudo ys-f66c-install-flclash`. Версия и checksum — в
  `config/versions.env`, на устройстве — в `/etc/ys-f66c/versions.env`.

Точный состав overlay — в [overlay/README.md](../overlay/README.md).

## Первый запуск

При первом запуске Armbian создаёт пользователя и настраивает сеть. Вход — через
SDDM. Автологин в образе не настроен; если он появился после first-run,
уберите `User=` из `/etc/sddm.conf.d/autologin.conf`.

Обновление desktop-слоя на уже установленной системе:

```sh
sudo ./scripts/install-overlay.sh --user <имя>
```

Политика обновлений, закрепление board-пакетов и откат — в
[updates.md](updates.md).

---

[← Железо](hardware.md) · [Оглавление](../README.md#документация) · [Поворот на этапе загрузки →](boot-rotation.md)
