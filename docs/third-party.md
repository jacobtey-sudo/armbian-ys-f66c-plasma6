# Third-party components

The overlay installs these applets system-wide:

- **Netspeed Widget** 3.1, Daniel Faust, GPL-2.0-or-later.
  Source: <https://github.com/dfaust/plasma-applet-netspeed-widget>
- **Window Buttons** 0.14.0, GPL-2.0-or-later.
  Source: <https://github.com/moodyhunter/applet-window-buttons6>
- **ksystemstats disk plugin patch**, GPL-2.0-or-later.
  Source: <https://invent.kde.org/plasma/ksystemstats>

## Optional applications

The image installs these applications from pinned upstream releases at build
time. The release binaries are not stored in git; a script downloads each
release and verifies its SHA256.

- **FlClash** 0.9.4 (arm64), GPL-3.0-or-later.
  Source: <https://github.com/chen08209/FlClash>
  Installer: `usr/local/bin/ys-f66c-install-flclash`