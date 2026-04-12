# dotfiles

Personal dotfiles for Arch Linux + Hyprland ricing.
Managed with symbolic links via `install.sh`.

## Stack

| Category      | Tool                     |
|---------------|--------------------------|
| WM            | Hyprland                 |
| Bar           | eww                      |
| Terminal      | WezTerm                  |
| Wallpaper     | swww                     |
| Lock screen   | hyprlock                 |
| Music         | MPD / YouTube Music      |
| Messages      | Vesktop + Gmail + Slack  |
| Font (text)   | JetBrains Mono           |
| Font (icons)  | Symbols Nerd Font        |
| Icon set      | Material Icons SVG       |
| Color scheme  | GitHub Primer Primitives |

## Fresh install

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Install required packages

```bash
sudo pacman -S git eww hyprland hyprlock swww playerctl \
               socat notmuch iw jq wezterm

yay -S vesktop-bin ttf-jetbrains-mono-nerd \
       ttf-material-symbols-variable-git
```

### 3. Run the installer

```bash
chmod +x ~/dotfiles/install.sh
./install.sh
```

### 4. Configure this machine

```bash
nano ~/.config/eww/device.conf
```

Key fields to set:

| Field            | Description                           |
|------------------|---------------------------------------|
| DEVICE_TYPE      | laptop or desktop                     |
| DEVICE_NAME      | Human-readable hostname               |
| MONITOR_COUNT    | Number of connected monitors          |
| WALLPAPER_PATH   | Path to wallpaper file for swww       |
| GMAIL_ADDRESS    | Gmail address for notmuch integration |
| SLACK_TOKEN      | Slack API token for unread badge      |
| EWW_FONT_SIZE    | Base font size in px (default: 13)    |

### 5. Start Hyprland

```bash
start-hyprland
```

## Adding a new icon

Use icon-patcher.sh to fetch and colorize a Material Icon.

```bash
~/dotfiles/eww/scripts/icon-patcher.sh <icon-name> <alias> "<color>"

# Example.
~/dotfiles/eww/scripts/icon-patcher.sh wifi_off net-wifi-off "#6e7681"
```

To add the icon permanently, append a line to the ICONS array
in ~/dotfiles/eww/scripts/icon-installer.sh and re-run it.

## Updating icons

```bash
# Re-run setup for all icons, skipping already-patched ones.
~/dotfiles/eww/scripts/icon-installer.sh

# Force re-patch all icons (e.g. after a color scheme change).
~/dotfiles/eww/scripts/icon-installer.sh --force

# Retry only icons that failed in the last run.
~/dotfiles/eww/scripts/icon-installer.sh --retry-failed
```

## Directory structure

```
~/dotfiles/
├── install.sh                  - Symlink creator and first-time setup.
├── .gitignore
├── README.md
├── eww/
│   ├── eww.yuck                - Widget definitions and window layout.
│   ├── eww.scss                - Styles using GitHub Primer color tokens.
│   ├── start-eww.sh            - Startup script with form detection.
│   ├── device.conf.example     - Per-machine config template.
│   ├── icons/                  - Generated SVG icons (git-ignored).
│   ├── material-icons/         - Sparse clone of material-design-icons (git-ignored).
│   └── scripts/
│       ├── icon-patcher.sh     - Fetch and colorize a single Material Icon.
│       ├── icon-installer.sh      - Batch icon setup for all EWW widgets.
│       ├── detect-form.sh      - Screen orientation and compact level detection.
│       ├── battery.sh          - Battery status with desktop auto-hide.
│       ├── network.sh          - Wi-Fi and LAN detection.
│       ├── workspaces.sh       - Hyprland workspace state via socket.
│       ├── music.sh            - MPD and YouTube Music via playerctl.
│       ├── messages.sh         - Discord, Gmail, and Slack unread counts.
│       └── power.sh            - Power menu actions.
├── hypr/
│   ├── hyprland.conf
│   └── hyprlock.conf
└── wezterm/
    └── wezterm.lua
```

## Per-machine setup notes

This repo uses a combination of hardware auto-detection and a
per-machine device.conf file to handle differences between machines.

| What              | How                                         |
|-------------------|---------------------------------------------|
| Battery presence  | Auto-detected via /sys/class/power_supply   |
| Monitor count     | Set manually in device.conf                 |
| Device type       | Set manually in device.conf                 |
| Wallpaper path    | Set manually in device.conf                 |
| API tokens        | Set manually in device.conf (git-ignored)   |

device.conf is never committed to git. Copy device.conf.example
and fill in the values for each new machine.
