# Архитектура

## Роли репозиториев

Проект разделён на три независимых слоя. Каждый слой можно обновлять
отдельно; связывает их файл пинов.

| Слой | Репозиторий | Что содержит |
| --- | --- | --- |
| Сборочный фреймворк | [`armbian/build`](https://github.com/armbian/build) | Docker-окружение, rootfs, установка пакетов, сборка образа |
| Board support | [`armbian-ys-f66c`](https://github.com/jacobtey-sudo/armbian-ys-f66c) | DTS, U-Boot, патчи ядра, board-конфиг, хуки железа |
| Desktop-слой | этот репозиторий | overlay Plasma 6, скрипты, документация, пины |

Board support подключается как `userpatches`: Armbian берёт оттуда
`config/boards/*.csc`, `kernel/`, `bootenv/`, `packages/` и `overlay/`.
Desktop-слой накладывается поверх него.

## Порядок сборки

`scripts/build.sh` выполняет:

1. клонирует `armbian/build` и переключает на `ARMBIAN_BUILD_COMMIT`;
2. клонирует board support в `userpatches` и переключает на
   `ARMBIAN_BASE_COMMIT`;
3. копирует `overlay/` этого репозитория поверх `userpatches/overlay/`;
4. запускает `./compile.sh ys-f66c-trixie build` из `WORKDIR`.

Дальше Armbian собирает ядро и rootfs, применяет `userpatches/overlay/`,
выполняет хуки board-конфига (`post_family_tweaks`, `post_family_tweaks_bsp`)
и упаковывает образ.

```text
config/versions.env
        │
        ├── armbian/build @ ARMBIAN_BUILD_COMMIT
        │        └── compile.sh ys-f66c-trixie build
        │
        ├── armbian-ys-f66c @ ARMBIAN_BASE_COMMIT
        │        └── userpatches/ (DTS, board-конфиг, хуки)
        │
        └── overlay/ этого репозитория
                 └── поверх userpatches/overlay/
                          └── output/images/*.img
```

## Приоритет overlay

Файлы с одинаковыми путями берутся из этого репозитория: `build.sh` копирует
`overlay/.` поверх board-support. Поэтому desktop-настройки живут здесь,
а board-support отвечает за железо и системные хуки.

Если хук board-конфига пишет тот же файл, что и overlay, побеждает тот, кто
выполняется позже. Для системных настроек (`/etc/xdg`, `/etc/skel`) оба слоя
пишут согласованное содержимое — это проверяется при изменении.

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
