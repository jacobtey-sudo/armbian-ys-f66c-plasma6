# YS-F66C: Plasma 6

Отдельный проект для сборки и интеграции Plasma 6 на планшете **Yisheng YS-F66C** (Rockchip RK3566).

## Границы проекта

- **Board support, U-Boot, DTS, kernel и образ Armbian** остаются в
  [jacobtey-sudo/armbian-ys-f66c](https://github.com/jacobtey-sudo/armbian-ys-f66c).
- Здесь хранятся **desktop-интеграция, overlay-конфиги, патчи, build-рецепт и release notes**
  для Plasma 6.
- Готовые образы и бинарники в git не коммитятся: только скрипты, конфиги и checksums.

## Текущее состояние

- База: Debian 13 `trixie`, Plasma `6.3.6`, Qt `6.8.2`.
- Ядро: `6.1.172-vendor-rk35xx`.
- Рабочая система перенесена на eMMC; microSD остаётся fallback.
- Исправлен CPU regulator: TCS4525 на `0x1c`, CPU работает до 1608 МГц.
- Префиксы: `/opt/plasma5` (legacy, не трогать) и `/opt/plasma6`.
- Производительность: [docs/performance.md](docs/performance.md).
- Поворот консоли и SDDM при загрузке: [docs/boot-rotation.md](docs/boot-rotation.md).
- Известные проблемы: [docs/known-issues.md](docs/known-issues.md).

## Структура

```text
config/     версии и пины базовой сборки
docs/       сборка, железо, известные проблемы
overlay/    файлы для установки в систему
patches/    патчи к Plasma/KWin/пакетам
scripts/    build/test/install-скрипты
```

## Сборка

Кратко: см. [docs/build.md](docs/build.md). Рецепт находится в стадии переноса из
рабочей системы; до его завершения используйте текущий образ и overlay.

## Связанные проекты

- [armbian-ys-f66c](https://github.com/jacobtey-sudo/armbian-ys-f66c) — board support.
- `/opt/plasma5` — сохранённая предыдущая сборка, используется как fallback.
