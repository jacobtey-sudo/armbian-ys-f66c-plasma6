# YS-F66C: Plasma 6

Проект desktop-слоя для планшета **Yisheng YS-F66C** (Rockchip RK3566): сборка
и интеграция Plasma 6, overlay-конфиги, скрипты и release notes.

## Границы проекта

- **Board support, U-Boot, DTS, патчи ядра, board-конфиг и BSP-пакеты** живут в
  публичном [jacobtey-sudo/armbian-ys-f66c](https://github.com/jacobtey-sudo/armbian-ys-f66c)
  и подключаются как `userpatches` на зафиксированном коммите.
- Здесь хранятся **desktop-интеграция, overlay, скрипты сборки/установки, пины
  версий и документация** для Plasma 6.
- Готовые образы и бинарники в git не коммитятся: только скрипты, конфиги и
  checksums (артефакты — в GitHub Releases).

## Текущее состояние

- База: Debian 13 `trixie`, Plasma `6.3.6`, Qt `6.8.2` (system-wide, `/usr`).
- Ядро: `6.1.172-vendor-rk35xx`.
- Проверенный носитель — microSD; eMMC на тестовом экземпляре занята Android.
- CPU regulator: TCS4525 на `0x1c`, CPU работает до 1608 МГц.
- `/opt/plasma5` и `/opt/plasma6` в текущем образе отсутствуют: overlay не
  содержит `/opt`, а Plasma ставится пакетами Debian в `/usr`. Префиксы в
  `config/versions.env` — задел на отдельную изолированную сборку, не текущее
  состояние.
- Экранная клавиатура: Maliit, работает в Plasma и SDDM.
- Desktop: Discover, Yakuake, Application Dashboard, Netspeed и Window Buttons.
- Прокси: FlClash (arm64), ставится из зафиксированного релиза при сборке.
- Производительность: [docs/performance.md](docs/performance.md).
- Поворот консоли и SDDM при загрузке: [docs/boot-rotation.md](docs/boot-rotation.md).
- Известные проблемы: [docs/known-issues.md](docs/known-issues.md).

## Быстрый старт

```sh
git clone https://github.com/jacobtey-sudo/armbian-ys-f66c-plasma6.git
cd armbian-ys-f66c-plasma6
./scripts/build.sh
```

Подробности, требования и ручная сборка — в [docs/build.md](docs/build.md).
Пины версий — в [config/versions.env](config/versions.env).
Сторонние апплеты — в [docs/third-party.md](docs/third-party.md).

## Структура

```text
config/     версии и пины (versions.env — источник истины)
docs/       сборка, железо, поворот, производительность, известные проблемы
overlay/    desktop-конфиги, которые попадают в образ (/etc/skel, systemd, environment.d)
patches/    патчи к Plasma/KWin/пакетам
scripts/    build.sh и install-overlay.sh
```

## Лицензия

GPL-2.0-only. См. [LICENSE](LICENSE).

## Связанные проекты

- [armbian-ys-f66c](https://github.com/jacobtey-sudo/armbian-ys-f66c) — board support.
