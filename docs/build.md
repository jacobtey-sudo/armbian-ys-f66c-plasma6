# Сборка

## Подход

Проект не форкает Armbian и не дублирует board support. Сборка собирается из
трёх закреплённых слоёв:

| Слой | Источник | Содержимое |
| --- | --- | --- |
| Сборочный фреймворк | `armbian/build` | Docker, rootfs, пакеты, упаковка образа |
| Board support | `armbian-ys-f66c` | DTS, U-Boot, патчи ядра, board-конфиг |
| Desktop Plasma 6 | этот репозиторий | `overlay/`, `scripts/`, `docs/`, пины |

Коммиты и версии — только в [`config/versions.env`](../config/versions.env).

## Требования

- Linux x86_64 (проверено на Debian 13 и Manjaro);
- Docker; пользователь должен быть в группе `docker`:
  ```sh
  sudo usermod -aG docker "$USER"   # затем перелогиниться
  ```
- ~50 ГБ свободного места (исходники, rootfs, кэши, образ);
- 8 ГБ RAM (на 4 ГБ собирается, но дольше);
- интернет.

Проверка Docker:

```sh
docker info
```

## Быстрая сборка

```sh
git clone https://github.com/jacobtey-sudo/armbian-ys-f66c-plasma6.git
cd armbian-ys-f66c-plasma6
./scripts/build.sh
```

Скрипт:

1. клонирует `armbian/build` в `./build` и переключает на
   `ARMBIAN_BUILD_COMMIT`;
2. клонирует board support в `./build/userpatches` и переключает на
   `ARMBIAN_BASE_COMMIT`;
3. копирует `overlay/` поверх `userpatches/overlay/`;
4. запускает `./compile.sh ys-f66c-trixie build`.

Рабочее дерево можно вынести:

```sh
WORKDIR=~/ys-build ./scripts/build.sh
```

Первая сборка занимает около 3 часов; повторные — заметно быстрее, потому что
ядро, пакеты и ccache остаются в `build/cache/`.

## Ручная сборка

Если нужно управлять деревом вручную, повторите шаги скрипта:

```sh
git clone https://github.com/armbian/build.git ~/ys-build
git -C ~/ys-build checkout --detach <ARMBIAN_BUILD_COMMIT>

git clone https://github.com/jacobtey-sudo/armbian-ys-f66c.git \
    ~/ys-build/userpatches
git -C ~/ys-build/userpatches checkout --detach <ARMBIAN_BASE_COMMIT>

cp -a overlay/. ~/ys-build/userpatches/overlay/

cd ~/ys-build
./compile.sh ys-f66c-trixie build
```

`<ARMBIAN_BUILD_COMMIT>` и `<ARMBIAN_BASE_COMMIT>` берутся из
`config/versions.env`.

## Проверка результата

```sh
ls -lh build/output/images/
sha256sum -c build/output/images/*.img.sha
```

После первого запуска на устройстве:

```sh
uname -r                     # 6.1.172-vendor-rk35xx
plasmashell --version         # 6.3.6
dpkg-query -W plasma-desktop libqt6core6
```

Дополнительно проверить: экран и поворот, тач, Wi-Fi/Ethernet, Bluetooth,
звук (динамик, наушники, микрофон), камеру, Maliit, кнопку питания.

## Артефакты

`output/images/` содержит:

- `*.img` — образ;
- `*.img.sha` — SHA256;
- `*.img.txt` — отчёт сборки (версии, пакеты, checksums).

Образы, `.deb` и архивы не коммитятся. Публикация — в
[docs/release.md](release.md).

## Если сборка не идёт

- **`permission denied` на Docker** — пользователь не в группе `docker` или
  не перелогинился.
- **мало места** — освободить `build/cache/` или указать другой `WORKDIR`.
- **сеть** — Armbian тянет пакеты Debian и Docker-базу; повторный запуск
  продолжит с кэша.
- **старый кэш после смены пина** — удалить `build/cache/rootfs/` и
  `build/cache/sources/` (ядро пересоберётся).

Лог сборки: `build/output/logs/`. Подробная диагностика на устройстве —
в [troubleshooting.md](troubleshooting.md).

---

[← Архитектура](architecture.md) · [Оглавление](../README.md#документация) · [Запись образа и первый запуск →](flashing.md)
