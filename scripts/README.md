# Scripts

Все скрипты работают из любого каталога: путь к репозиторию вычисляется от
`BASH_SOURCE`. Требуется `bash` и стандартные утилиты; `build.sh` дополнительно
требует Docker.

## `build.sh`

Собирает образ целиком:

1. клонирует Armbian build framework в `WORKDIR` и переключает на
   `ARMBIAN_BUILD_COMMIT`;
2. клонирует board support `armbian-ys-f66c` в `WORKDIR/userpatches` и
   переключает на `ARMBIAN_BASE_COMMIT`;
3. удаляет файлы прошлого запуска: возвращает отслеживаемые board-support
   файлы и удаляет только свои untracked-файлы (манифест —
   `userpatches/.ys-f66c-plasma6-files.list`);
4. копирует desktop-слой в `userpatches`: board-конфиг, extension и
   `customize-image.sh`;
5. копирует `overlay/.` в `userpatches/overlay/`;
6. пишет `/etc/ys-f66c/versions.env` через `gen-runtime-pins.sh`;
7. запускает `./compile.sh "$BOARD_CONFIG" build`.

По умолчанию `WORKDIR=./build` (в `.gitignore`). Переопределение:

```sh
WORKDIR=~/ys-build ./scripts/build.sh
```

Переменные читаются из `config/versions.env`; `BOARD_CONFIG` можно
переопределить окружением (по умолчанию `ys-f66c-plasma6`).

Результат: `$WORKDIR/output/images/*.img` (+ `.sha` / `.txt`), лог —
`$WORKDIR/output/logs/`.

Скрипт идемпотентен: повторный запуск использует существующее дерево и
кэши. Он **не** удаляет `WORKDIR`, не чистит кэш и не трогает носители.

## `gen-runtime-pins.sh`

Пишет runtime-файл пинов, который читают скрипты на устройстве:

```sh
./scripts/gen-runtime-pins.sh /etc/ys-f66c/versions.env
```

Значения берёт из `config/versions.env` (`FLCLASH_VERSION`,
`FLCLASH_SHA256`). `build.sh` кладёт файл в образ, `install-overlay.sh` —
в `/etc` живой системы.

## `install-overlay.sh`

Ставит desktop-overlay на уже прошитую систему:

```sh
sudo ./scripts/install-overlay.sh
sudo ./scripts/install-overlay.sh --user <имя>
```

- копирует `overlay/etc/.` в `/etc` (в первую очередь `/etc/skel`);
- копирует `overlay/usr/.` в `/usr`;
- выставляет `root:root` на системные файлы, чтобы они не остались
  принадлежать пользователю, из-под которого сделан checkout;
- обновляет кэши схем и `.desktop`-файлов;
- пишет `/etc/ys-f66c/versions.env` (runtime-пины FlClash);
- включает `ys-f66c-bt-autoconnect.service`;
- с `--user NAME` копирует `etc/skel/.config` в домашний каталог пользователя
  и выставляет владельца (пользователь и его основная группа).

Раздел eMMC монтирует board support (`ys-f66c-emmc-mount.service`); скрипт
overlay его не настраивает.

**Внимание:** пользовательские настройки в `~/.config` перезаписываются.
Сделайте резервную копию, если в них есть изменения.

## `smoke-test.sh`

Проверка уже прошитой системы без изменения файлов:

```sh
./scripts/smoke-test.sh
sudo ./scripts/smoke-test.sh --user <имя>
./scripts/smoke-test.sh --strict
```

Скрипт проверяет плату, ядро и DTB, корень и свободное место, failed units,
поворот fbcon/KWin, звук, Bluetooth, камеру `/dev/video10`, eMMC,
thermal-зоны, governor CPU, сеть и сессию KWin. Коды возврата: `0` — ошибок
нет, `1` — ошибки, `2` — предупреждения при `--strict` (или чужая плата без
`--force`).

Запускайте из терминала Plasma, чтобы были доступны проверки PipeWire и
графической сессии. При запуске через SSH без `--user` эти проверки будут
пропущены.

## Правила

- `set -euo pipefail`;
- пины — только из `config/versions.env`;
- не писать на eMMC/носитель без явного подтверждения;
- логировать версии и checksums;
- не хранить секреты, токены и пароли;
- системные файлы — только `root:root`.
