# Configuration

`versions.env` — единственный источник зафиксированных версий и путей. Его
читает `scripts/build.sh`; документация ссылается на него, а не дублирует
коммиты.

Правила:

- не менять пины «по ходу» без отдельного коммита;
- для экспериментальной сборки — отдельная ветка или временный файл;
- секреты, токены и пароли в этот каталог не добавлять;
- пин всегда указывает на существующий публичный коммит.

## Пины

- `ARMBIAN_BUILD_REPO` / `ARMBIAN_BUILD_COMMIT` — сборочный фреймворк Armbian;
- `ARMBIAN_BASE_REPO` / `ARMBIAN_BASE_COMMIT` — board support и консольная
  база (`armbian-ys-f66c`), которая кладётся в `userpatches`; пин указывает на
  коммит после разделения, проверка на microSD — следующий шаг;
- `BOARD_CONFIG` — имя board-конфига из этого репозитория
  (`config/board/config-<name>.conf`);
- `DISTRO`, `PLASMA_VERSION`, `QT_VERSION`, `KERNEL_VERSION` — для
  документации и release notes;
- `FLCLASH_VERSION` / `FLCLASH_SHA256` — опциональный FlClash. Из них
  `scripts/gen-runtime-pins.sh` собирает `/etc/ys-f66c/versions.env` для
  образа и для `scripts/install-overlay.sh`.
