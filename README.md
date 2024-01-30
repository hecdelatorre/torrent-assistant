# Torrent Assistant

Torrent Assistant is a bash script designed to manage torrent directories and execute torrents using rtorrent. It provides a simple command-line interface to create, view, and delete torrent directories stored in an SQLite database.

### Dependencies

- `bash`
- `sqlite3`
- `rtorrent`
- `xterm`

### Installation

#### Debian

```bash
sudo apt update
sudo apt install bash sqlite3 rtorrent xterm
```

#### Fedora

```bash
sudo dnf install bash sqlite rtorrent xterm
```

#### Arch Linux

```bash
sudo pacman -S bash sqlite rtorrent xterm
```

### Clone Repository

To clone the Torrent Assistant repository, use the following command:

```bash
git clone https://codeberg.org/hecdelatorre/torrent-assistant.git
```

### Run Without Cloning

You can run Torrent Assistant without cloning the repository using the following command:

```bash
bash -c "$(curl -fsSL https://codeberg.org/hecdelatorre/torrent-assistant/raw/branch/main/index-min.sh)"
```

### License

Torrent Assistant is licensed under the GNU General Public License v3.0 (GPL-3.0). See the [LICENSE](LICENSE) file for details.
