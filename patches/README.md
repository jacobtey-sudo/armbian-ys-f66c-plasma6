# Patches

Патчи должны быть минимальными и иметь в имени компонент и версию:

```text
ksystemstats-6.3.4-emmc.patch
kwin-6.3.6-fix-something.patch
qt6-declarative-6.8.2-backport-XXXX.patch
```

Для каждого патча в commit message указывать:

- upstream commit/issue;
- почему недостаточно обновления пакета;
- как проверялось.

## `ksystemstats-6.3.4-emmc.patch`

Патч к `ksystemstats` 6.3.4 (Plasma):

- заполняет сенсоры диска сразу, не дожидаясь подписки панели;
- считает свободное место через `statvfs()` вместо KIO-задания;
- не скрывает раздел данных eMMC, смонтированный в `/mnt/emmc`, хотя он
  flash-backed и помечен как системный.

Без патча виджет «Использование EMMC» показывает нули или не находит сенсор.
Патч не меняет формат сенсоров; настройки виджета ссылаются на UUID файловой
системы раздела.

### Пересборка плагина

Нужен arm64-хост или кросс-сборка и зависимости KDE Frameworks/Plasma:

```sh
sudo apt build-dep ksystemstats
apt source ksystemstats
cd ksystemstats-6.3.4
patch -p1 < /path/to/ksystemstats-6.3.4-emmc.patch
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build -j"$(nproc)"
```

Собранный `ksystemstats_plugin_disk.so` устанавливается в
`/usr/lib/aarch64-linux-gnu/qt6/plugins/ksystemstats/` и попадает в overlay
по этому пути. Точный каталог сборки зависит от версии upstream — смотреть
вывод `cmake --build` и `find build -name 'ksystemstats_plugin_disk.so'`.

После замены плагина перезапустить `ksystemstats`/Plasma и проверить, что
виджет видит раздел.

## Плагин Window Buttons

`libappletdecorationplugin.so` — не патч, а сборка upstream-апплета
Window Buttons 0.14.0 под arm64. Исходники и лицензия — в
[`docs/third-party.md`](../docs/third-party.md).
