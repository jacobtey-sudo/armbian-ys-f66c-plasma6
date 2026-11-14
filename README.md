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

- База: Debian 13 `trixie`, Plasma `6.3.6`, Qt `6.8.2`.
- Ядро: `6.1.172-vendor-rk35xx`.
- Рабочая система перенесена на eMMC; microSD остаётся fallback.
- CPU regulator: TCS4525 на `0x1c`, CPU работает до 1608 МГц.
- Префиксы: `/opt/plasma5` (legacy, не трогать) и `/opt/plasma6`.
- Экранная клавиатура: Maliit, работает в Plasma и SDDM.
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

## Структура

```text
config/     версии и пины (versions.env — источник истины)
docs/       сборка, железо, поворот, производительность, известные проблемы
overlay/    desktop-конфиги, которые попадают в образ (/etc/skel)
patches/    патчи к Plasma/KWin/пакетам (пока пусто)
scripts/    build.sh и install-overlay.sh
```

## Лицензия

GPL-2.0-only. См. [LICENSE](LICENSE).

## Связанные проекты

- [armbian-ys-f66c](https://github.com/jacobtey-sudo/armbian-ys-f66c) — board support.
- `/opt/plasma5` — сохранённая предыдущая сборка, используется как fallback.
