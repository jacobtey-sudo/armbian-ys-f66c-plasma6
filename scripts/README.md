# Scripts

Оба скрипта работают из любого каталога: путь к репозиторию вычисляется от
`BASH_SOURCE`. Требуется `bash` и стандартные утилиты; `build.sh` дополнительно
требует Docker.

## `build.sh`

Собирает образ целиком:

1. клонирует Armbian build framework в `WORKDIR` и переключает на
   `ARMBIAN_BUILD_COMMIT`;
2. клонирует board support `armbian-ys-f66c` в `WORKDIR/userpatches` и
   переключает на `ARMBIAN_BASE_COMMIT`;
3. копирует `overlay/.` поверх `userpatches/overlay/`;
4. запускает `./compile.sh "$BOARD_CONFIG" build`.

По умолчанию `WORKDIR=./build` (в `.gitignore`). Переопределение:

```sh
WORKDIR=~/ys-build ./scripts/build.sh
```

Переменные читаются из `config/versions.env`; `BOARD_CONFIG` можно
переопределить окружением (по умолчанию `ys-f66c-trixie`).

Результат: `$WORKDIR/output/images/*.img` (+ `.sha` / `.txt`), лог —
`$WORKDIR/output/logs/`.

Скрипт идемпотентен: повторный запуск использует существующее дерево и
кэши. Он **не** удаляет `WORKDIR`, не чистит кэш и не трогает носители.

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
- включает `ys-f66c-bt-autoconnect.service`;
- с `--user NAME` копирует `etc/skel/.config` в домашний каталог пользователя
  и выставляет владельца (пользователь и его основная группа).

Раздел eMMC монтирует board support (`ys-f66c-emmc-mount.service`); скрипт
overlay его не настраивает.

**Внимание:** пользовательские настройки в `~/.config` перезаписываются.
Сделайте резервную копию, если в них есть изменения.

## Правила

- `set -euo pipefail`;
- пины — только из `config/versions.env`;
- не писать на eMMC/носитель без явного подтверждения;
- логировать версии и checksums;
- не хранить секреты, токены и пароли;
- системные файлы — только `root:root`.
