# Scripts

## `build.sh`

Собирает образ целиком:

1. клонирует Armbian build framework и ставит его на коммит из
   `config/versions.env`;
2. клонирует публичный board support `armbian-ys-f66c` в `userpatches` на
   зафиксированный коммит;
3. накладывает `overlay/` этого репозитория поверх board support;
4. запускает `./compile.sh ys-f66c-trixie build`.

По умолчанию рабочее дерево — `./build` (в `.gitignore`). Можно переопределить:

```sh
WORKDIR=~/ys-build ./scripts/build.sh
```

Результат: `$WORKDIR/output/images/*.img` (+ `.sha` / `.txt`).

## `install-overlay.sh`

Ставит desktop-overlay на уже прошитую систему: файлы копируются в `/etc`
(в первую очередь `/etc/skel`), а с `--user NAME` ещё и в `~NAME/.config`.

```sh
sudo ./scripts/install-overlay.sh
sudo ./scripts/install-overlay.sh --user <имя>
```

## Правила

- `set -euo pipefail`;
- пины — только из `config/versions.env`;
- не писать на eMMC/носитель без явного подтверждения;
- логировать версии и checksums;
- не хранить секреты, токены и пароли.
