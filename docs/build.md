# Сборка

## Подход

Проект не форкает Armbian и не дублирует board support. Board support берётся
из публичного `armbian-ys-f66c` на коммите из `config/versions.env`, а этот
репозиторий добавляет desktop-слой Plasma 6 (`overlay/`) — так же, как в
`scripts/build.sh`.

Два слоя:

| Слой | Где хранится | Содержимое |
| --- | --- | --- |
| Board support | `armbian-ys-f66c` (public) | DTS, U-Boot, патчи ядра, board-конфиг, BSP-пакеты |
| Desktop Plasma 6 | этот репозиторий | `overlay/`, `scripts/`, `docs/`, пины |

## Требования

- Linux x86_64 build host;
- `git`, `docker` (или совместимый рантайм) и зависимости Armbian build
  framework;
- ~50 ГБ свободного места (исходники, rootfs, кэши, образ);
- для bring-up желателен UART, если образ не стартует;
- отдельная microSD для проверки, пока eMMC не стала основной системой.

## Прошивка validated-образа

Актуальный проверенный образ и его checksums публикуются в GitHub Releases
этого репозитория. Образ пишется на отдельный носитель, проверяется загрузка,
панель, тач, звук, Wi-Fi/BT, камера и Plasma. Только после этого система
переносится на eMMC; microSD остаётся как fallback.

## Сборка из исходников

```sh
git clone https://github.com/jacobtey-sudo/armbian-ys-f66c-plasma6.git
cd armbian-ys-f66c-plasma6
./scripts/build.sh
```

Скрипт:

1. клонирует Armbian build framework и ставит его на `ARMBIAN_BUILD_COMMIT`;
2. клонирует `armbian-ys-f66c` в `userpatches` на `ARMBIAN_BASE_COMMIT`;
3. накладывает `overlay/` этого репозитория поверх board support;
4. запускает `./compile.sh ys-f66c-trixie build`.

Рабочее дерево по умолчанию — `./build`; переопределяется через `WORKDIR`:

```sh
WORKDIR=~/ys-build ./scripts/build.sh
```

### Ручная сборка

Если нужно управлять деревом вручную, повторите шаги из `scripts/build.sh`:

```sh
git clone https://github.com/armbian/build.git ~/ys-build
git -C ~/ys-build checkout --detach <ARMBIAN_BUILD_COMMIT>

git clone https://github.com/jacobtey-sudo/armbian-ys-f66c.git ~/ys-build/userpatches
git -C ~/ys-build/userpatches checkout --detach <ARMBIAN_BASE_COMMIT>

cp -a overlay/. ~/ys-build/userpatches/overlay/

cd ~/ys-build
./compile.sh ys-f66c-trixie build
```

Коммиты и версии — в `config/versions.env`, не в командах из документации.

## Проверка

- сверить SHA256 результата с `output/images/*.sha`;
- после запуска board: `uname -r` должен давать версию из
  `KERNEL_VERSION`;
- Plasma/Qt версии: `plasmashell --version`, `qmake6 --version`;
- OSK: Maliit работает и в Plasma, и в SDDM;
- зафиксировать результат в `docs/known-issues.md`, если что-то не так.

## Установка overlay на уже прошитую систему

Если образ уже стоит и нужно обновить только desktop-слой:

```sh
sudo ./scripts/install-overlay.sh                 # в /etc/skel
sudo ./scripts/install-overlay.sh --user <имя>    # плюс в ~<имя>/.config
```

## Артефакты

Образы, `.deb`, `.tar.*` и большие бинарники — в GitHub Releases, не в git.
Для каждого артефакта хранить SHA256 и версии из `config/versions.env`.
