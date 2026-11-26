# Обновления

Образ — это Debian 13 `trixie` с board-support и ядром, зафиксированными в
[`config/versions.env`](../config/versions.env). Обновлять систему можно, но
не всё сразу: пользовательские пакеты и board-слой имеют разную цену ошибки.

Перед любым обновлением:

- сделайте резервную копию eMMC по [recovery.md](recovery.md);
- проверьте свободное место (`df -h /`);
- обновляйтесь при стабильном питании, лучше от UPS;
- если возможно, сначала проверьте обновление на microSD, а не на рабочей
  системе в eMMC.

## Что можно обновлять через apt

Штатные пакеты Debian и KDE: Plasma, Qt, приложения, библиотеки, шрифты.
Обычное обновление:

```sh
sudo apt update
sudo apt upgrade
```

`apt upgrade` не удаляет установленные пакеты. Читайте список изменений перед
подтверждением: `apt full-upgrade` может удалить или заменить пакеты и
требует отдельной проверки.

После обновления:

```sh
sudo reboot
systemctl --failed
journalctl -b -p err
```

Если Plasma или приложения сломались, вернитесь к резервной копии либо
откатите конкретный пакет. История apt — в `/var/log/apt/history.log`.

## Что не обновляется через apt

Ядро, DTB, U-Boot и board-пакеты собраны из board support с патчами платы:
панель, тачскрин, регулятор CPU, TSADC, Wi-Fi/BT, кнопка питания. В
официальном репозитории Armbian этих изменений для YS-F66C нет. Обновление
таких пакетов «сверху» может заменить DTB или загрузчик и сломать загрузку,
экран или сеть.

До первого `apt upgrade` закрепите board-слой:

```sh
sudo apt-mark hold \
  linux-image-vendor-rk35xx \
  linux-dtb-vendor-rk35xx \
  linux-u-boot-ys-f66c-vendor \
  armbian-bsp-cli-ys-f66c-vendor \
  armbian-firmware
```

Проверка:

```sh
apt-mark showhold
dpkg -l | grep -E 'linux-(image|dtb|u-boot)|armbian-(bsp|firmware)'
uname -r
```

Ожидаемо: `6.1.172-vendor-rk35xx`, пакеты `26.11.0-trunk` и пять строк в
`apt-mark showhold`. Если `linux-headers-vendor-rk35xx` установлены, добавьте
их в hold тем же способом.

`armbian-firmware` закреплён вместе с board-слоем, потому что в нём лежат
прошивки Wi-Fi/Bluetooth для обеих ревизий платы. Обновлять его отдельно
можно только после проверки на microSD.

### Осознанное обновление board-слоя

Не снимайте hold, чтобы «просто поставить свежее ядро». Правильный путь:

1. Обновите пины в `config/versions.env` в репозитории.
2. Соберите новый образ по [build.md](build.md).
3. Запишите его на microSD и проверьте загрузку, экран, звук, Wi-Fi/BT,
   камеру и eMMC.
4. Только после этого устанавливайте на eMMC или переносите пакеты.

Если нужно обновить только один пакет, сначала снимите hold, установите
проверенную версию и верните hold:

```sh
sudo apt-mark unhold linux-image-vendor-rk35xx
sudo apt install linux-image-vendor-rk35xx
sudo apt-mark hold linux-image-vendor-rk35xx
```

Не удаляйте старое ядро, пока не убедились, что новое загружается.

## Mesa и графика

Mesa в образе — из `trixie-backports` (26.1.6), потому что Mesa 25.0.7 из
`trixie` ломает Qt5-приложения на Panfrost. Обычный `apt upgrade` может
подтянуть более новую версию из backports. Если после обновления KWin или
приложения падают с ошибкой GL/stack smashing:

```sh
dpkg -l mesa-libgallium libgl1-mesa-dri
journalctl -b -p err | grep -i -E 'mesa|panfrost|segfault'
```

Вернитесь к резервной копии или установите предыдущую версию Mesa из
`/var/cache/apt/archives`, если она сохранилась. Подробности о причине —
в [known-issues.md](known-issues.md) и [performance.md](performance.md).

## FlClash

FlClash не входит в apt и не обновляется сам. В образе стоит версия из
`config/versions.env`; установщик читает её из `/etc/ys-f66c/versions.env`
и проверяет SHA256 скачанного `.deb`. Обновление — отдельное осознанное
действие:

```sh
dpkg-query -W -f='${Version}\n' flclash
sudo /usr/local/bin/ys-f66c-install-flclash
```

Если установщик уже считает версию актуальной, он ничего не делает. Новую
версию сначала добавляют в пины репозитория и проверяют на microSD; не
скачивайте `.deb` из случайного источника.

## Обновление overlay без перепрошивки

Desktop-слой (настройки Plasma, Maliit, панель, сервисы) можно обновить на
уже установленной системе:

```sh
cd armbian-ys-f66c-plasma6
git pull
sudo ./scripts/install-overlay.sh --user <имя>
sudo systemctl restart sddm
```

Скрипт копирует `/etc` и `/usr` из `overlay/` и перезаписывает
пользовательские файлы в `~/.config`. Сделайте их резервную копию. Скрипт не
удаляет файлы, которых больше нет в overlay, и не меняет ядро, DTB или
U-Boot.

Если нужно вернуть предыдущую версию overlay:

```sh
git checkout <предыдущий-тег>
sudo ./scripts/install-overlay.sh --user <имя>
```

После отката проверьте, не остались ли в `~/.config` файлы от новой версии.
Надёжнее восстановить `~/.config` из резервной копии.

## Откат системы

1. **Один пакет.** `sudo apt install <пакет>=<версия>`; версия должна ещё
   быть доступна в репозитории или в `/var/cache/apt/archives`.
2. **Overlay.** Предыдущий тег и `install-overlay.sh`, затем проверка
   `~/.config`.
3. **Вся система.** Загрузитесь с microSD и восстановите eMMC из копии по
   [recovery.md](recovery.md), либо переустановите релизный образ.
4. **Образ.** Скачайте предыдущий релиз из
   [Releases](https://github.com/jacobtey-sudo/armbian-ys-f66c-plasma6/releases)
   и запишите на microSD; checksums есть в [release.md](release.md).

После отката выполните проверку из
[flashing.md](flashing.md#проверка-после-прошивки) и
`systemctl --failed`.

## Автоматические обновления

Периодические задачи apt в образе есть, но автоматическая установка
обновлений не настроена. Это сделано намеренно: внезапное обновление
board-пакетов или перезагрузка не должны ломать устройство без вашего
участия. Если включаете `unattended-upgrades`, настройте его только на
`trixie-security` и заранее закрепите board-пакеты.

---

[← Восстановление](recovery.md) · [Оглавление](../README.md#документация) · [Железо →](hardware.md)
