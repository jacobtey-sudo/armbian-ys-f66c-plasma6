# Configuration

`versions.env` — единственный источник зафиксированных версий и путей. Его
читает `scripts/build.sh`.

Правила:

- не менять пины «по ходу» без отдельного коммита;
- для экспериментальной сборки делать отдельную ветку или временный файл;
- секреты, токены и пароли в этот каталог не добавлять.

## Пины

- `ARMBIAN_BASE_REPO` / `ARMBIAN_BASE_COMMIT` — публичный board support
  (`armbian-ys-f66c`), который кладётся в `userpatches`;
- `ARMBIAN_BUILD_REPO` / `ARMBIAN_BUILD_COMMIT` — сборочный фреймворк Armbian;
- `BOARD_CONFIG` — имя конфига (`config-<name>.conf`) из board support;
- `PLASMA_VERSION`, `QT_VERSION`, `KERNEL_VERSION` — для документации и
  release notes.
