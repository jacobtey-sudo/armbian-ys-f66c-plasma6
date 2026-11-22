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
- `ARMBIAN_BASE_REPO` / `ARMBIAN_BASE_COMMIT` — board support
  (`armbian-ys-f66c`), который кладётся в `userpatches`;
- `BOARD_CONFIG` — имя board-конфига (`config-<name>.conf`) из board support;
- `DISTRO`, `PLASMA_VERSION`, `QT_VERSION`, `KERNEL_VERSION` — для
  документации и release notes.
