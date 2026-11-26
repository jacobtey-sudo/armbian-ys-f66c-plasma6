# Архитектура

## Роли репозиториев

Проект разделён на три независимых слоя. Каждый слой можно обновлять
отдельно; связывает их файл пинов.

| Слой | Репозиторий | Что содержит |
| --- | --- | --- |
| Сборочный фреймворк | [`armbian/build`](https://github.com/armbian/build) | Docker-окружение, rootfs, установка пакетов, сборка образа |
| Board support и консоль | [`armbian-ys-f66c`](https://github.com/jacobtey-sudo/armbian-ys-f66c) | DTS, U-Boot, патчи ядра, board-файл, железные хуки и сервисы, консольный config |
| Desktop-слой | этот репозиторий | board-конфиг Plasma 6, extension с KDE/SDDM-хуками, overlay, скрипты, документация, пины |

Board support подключается как `userpatches`: Armbian берёт оттуда
`config/boards/*.csc`, `kernel/`, `bootenv/`, `packages/` и
`customize-image.sh`. Desktop-слой добавляет board-конфиг, extension и
overlay. Board support не устанавливает рабочий стол.

## Порядок сборки

`scripts/build.sh` выполняет:

1. клонирует `armbian/build` и переключает на `ARMBIAN_BUILD_COMMIT`;
2. клонирует board support в `userpatches` и переключает на
   `ARMBIAN_BASE_COMMIT`;
3. копирует desktop-слой:
   - `config/board/config-ys-f66c-plasma6.conf` → `userpatches/config-*.conf`;
   - `extensions/ys-f66c-plasma6.sh` → `userpatches/extensions/`;
   - `customize-image.sh` → `userpatches/customize-image.sh`;
   - `overlay/` → `userpatches/overlay/`;
4. запускает `./compile.sh ys-f66c-plasma6 build` из `WORKDIR`.

Board-конфиг включает extension. Extension добавляет desktop-пакеты через
`add_packages_to_image` и KDE/SDDM-хуки через `post_family_tweaks*`.
`customize-image.sh` копирует overlay, ставит Mesa из backports и FlClash.

Дальше Armbian собирает ядро и rootfs, выполняет хуки board-файла и
extension, применяет overlay и упаковывает образ.

```text
config/versions.env
        │
        ├── armbian/build @ ARMBIAN_BUILD_COMMIT
        │        └── compile.sh ys-f66c-plasma6 build
        │
        ├── armbian-ys-f66c @ ARMBIAN_BASE_COMMIT
        │        └── userpatches/ (DTS, board-файл, консольная база)
        │
        └── desktop-слой этого репозитория
                 ├── config/board/config-ys-f66c-plasma6.conf
                 ├── extensions/ys-f66c-plasma6.sh
                 ├── customize-image.sh
                 └── overlay/
                          └── output/images/*.img
```

## Overlay и хуки

Board support не содержит overlay. Desktop-слой — единственный источник
overlay и desktop-настроек. `build.sh` копирует `overlay/.` в
`userpatches/overlay/`.

Если extension и overlay пишут один файл, побеждает тот, кто выполняется
позже. Для системных настроек (`/etc/xdg`, `/etc/skel`) оба слоя пишут
согласованное содержимое — это проверяется при изменении.

## Разделение board-support и desktop

Разделение реализовано:

- `armbian-ys-f66c` — board support и консольная база: ядро, DTS, U-Boot,
  железные хуки и сервисы. `BUILD_DESKTOP=no`, без overlay и KDE-хуков.
- `armbian-ys-f66c-plasma6` — десктоп: board-конфиг
  `config/board/config-ys-f66c-plasma6.conf`, extension
  `extensions/ys-f66c-plasma6.sh`, `customize-image.sh` и overlay.

Extension добавляет пакеты `kamoso`, Maliit, `yakuake`, `synaptic` и
`plasma-widgets-addons`, а также хуки powerdevil, системного звонка, SDDM,
поворота тача и QML-кэша.

`ARMBIAN_BASE_COMMIT` пока указывает на коммит до разделения: образ
`v26.11.0` собран из него. Порядок перехода:

1. пересобрать образ с новым коммитом base;
2. проверить загрузку и рабочий стол на microSD;
3. отдельным коммитом сдвинуть `ARMBIAN_BASE_COMMIT` на этот коммит.

## Пины

`config/versions.env` — единственный источник зафиксированных версий.
Скрипты читают только его; в документации не должно быть «магических»
коммитов и версий. `scripts/gen-runtime-pins.sh` переносит нужные пины
(FlClash) в `/etc/ys-f66c/versions.env` внутри образа и при установке
overlay.

Правила:

- обновление пина — отдельный коммит с причиной;
- сначала проверка на microSD, затем обновление документации;
- `ARMBIAN_BUILD_COMMIT` и `ARMBIAN_BASE_COMMIT` всегда указывают на
  существующие публичные коммиты.

## Артефакты

- Образ, `.sha` и `.txt`-отчёт создаются в `WORKDIR/output/images/`.
- В git не коммитятся образы, `.deb`, архивы и логи.
- В overlay допустимы только небольшие собранные апплеты и плагины, исходники
  и инструкции по пересборке которых описаны в
  [`patches/`](../patches/README.md) и
  [`docs/third-party.md`](third-party.md).
- Релизы и checksums публикуются отдельно — см. [release.md](release.md).

## Границы ответственности

- **Board support** не содержит пользовательских настроек Plasma и не задаёт
  внешний вид рабочего стола.
- **Desktop-слой** не правит DTS, U-Boot и ядро; если для работы нужен
  железный хук, он добавляется в board support отдельным коммитом.
- **Этот репозиторий** не форкает Armbian: все изменения сборочной
  инфраструктуры остаются в пине `armbian/build`.

## Машинно-зависимые данные

В репозитории нет серийных номеров, MAC-адресов, IP-адресов, паролей и
ключей. MAC в `bluedevilglobalrc` — заглушки.

Единственная привязка к разметке носителя — UUID файловой системы раздела
eMMC в настройках виджета «Использование EMMC». Если раздел пересоздан,
UUID обновляется в `/etc/fstab` и в настройках виджета; подробности —
в [desktop.md](desktop.md#emmc).

---

[← Оглавление](../README.md#документация) · [Сборка →](build.md)
