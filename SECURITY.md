# Безопасность

## Как сообщить

Не открывайте публичный issue для уязвимостей. Используйте
[Security Advisories](https://github.com/jacobtey-sudo/armbian-ys-f66c-plasma6/security/advisories/new).

Приложите:

- версию релиза и checksum образа;
- шаги воспроизведения;
- ожидаемый и фактический результат.

## Что не присылать

- токены, пароли, SSH-ключи, PAT;
- MAC-адреса, серийные номера SoC и другие личные данные;
- дампы `/etc/shadow`.

Отредактируйте вывод `armbianmonitor -u` и `journalctl -b -p err` перед
отправкой.

## Поддержка

Это пользовательская сборка для одной платы, без гарантий. Релизы выходят
как pre-release. Обновляйте систему по правилам
[docs/updates.md](docs/updates.md); не ставьте ядро, DTB или U-Boot из
случайного источника.

## Область

Относятся к делу: уязвимости в `scripts/`, overlay, board support и в
самом образе. Уязвимости в Debian, KDE, ядре Linux и FlClash сообщайте их
разработчикам и ставьте обновление через [docs/updates.md](docs/updates.md).

---

[Оглавление](README.md#документация)
