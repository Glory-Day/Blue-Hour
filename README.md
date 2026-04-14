> [!WARNING]
> This project is currently a **Work in Progress**. Features may be incomplete, unstable, or subject to change without notice.

# Blue Hour

A Hyprland + eww ricing for Arch Linux, inspired by the soft blue hues of early dawn.

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
| Icon set      | Material Icons SVG       |
| Color scheme  | GitHub Primer Primitives |

## Fresh install

### 1. Clone the repository

```bash
git clone git@github.com:Glory-Day/Blue-Hour.git ~/dotfiles
cd ~/dotfiles
```

### 2. Install required packages

```bash
sudo pacman -S hyprland swww hyprlock notmuch iw python ffmpeg \
               socat playerctl jq git base-devel openssh \
               pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
               fcitx5 fcitx5-hangul fcitx5-gtk fcitx5-qt fcitx5-configtool \
               grim slurp wl-clipboard noto-fonts-cjk less

# wezterm-git must be installed from the AUR.
# The stable wezterm package has known issues on Wayland with Hyprland.
yay -S wezterm-git eww vesktop-bin ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-mono
```

### 3. Enable audio services

```bash
systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber
```

### 4. Run the installer

```bash
chmod +x ~/dotfiles/install.sh
./install.sh
```

### 5. Configure this machine

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

### 6. Start Hyprland

```bash
start-hyprland
```

## Keybindings

| Key | Action |
|-----|--------|
| `Super + Q` | Open terminal (wezterm) |
| `Super + C` | Close active window |
| `Super + S` | Area screenshot to clipboard |
| `Super + Shift + S` | Full screen screenshot to clipboard |
| `Super + L` | Lock screen (hyprlock) |
| `Super + 1-9` | Switch workspace |
| `Ctrl + Space` | Toggle Korean input (fcitx5) |

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
├── install.sh                      - Symlink creator and first-time setup.
├── .gitignore
├── README.md
├── LICENSE
├── eww/
│   ├── eww.yuck                    - Entry point. Imports all modules.
│   ├── eww.scss                    - Entry point. Imports all styles.
│   ├── eww-launcher.sh             - Startup script. Starts daemon and opens bars.
│   ├── device.conf.example         - Per-machine config template.
│   ├── icons/                      - Generated SVG icons (git-ignored).
│   ├── material-icons/             - Sparse clone of material-design-icons (git-ignored).
│   ├── modules/                    - EWW widget definitions.
│   │   ├── variables.yuck          - All defpoll and deflisten definitions.
│   │   ├── os.yuck                 - OS island widget.
│   │   ├── workspace.yuck          - Workspace island widget.
│   │   ├── time.yuck               - Time-Date island widget.
│   │   ├── music.yuck              - Music island widget.
│   │   ├── messages.yuck           - Messages island widget.
│   │   ├── system.yuck             - System island widget.
│   │   ├── power.yuck              - Power island and menu widget.
│   │   ├── bar.yuck                - Horizontal and vertical bar layouts.
│   │   ├── popups.yuck             - Stub popup widgets.
│   │   └── windows.yuck            - defwindow definitions (generated).
│   ├── styles/                     - SCSS style modules.
│   │   ├── _variables.scss         - Color tokens and size variables.
│   │   ├── _base.scss              - Global reset and bar container.
│   │   ├── _island.scss            - Shared island base styles.
│   │   ├── _os.scss                - OS island styles.
│   │   ├── _workspace.scss         - Workspace island styles.
│   │   ├── _time.scss              - Time-Date island styles.
│   │   ├── _music.scss             - Music island styles.
│   │   ├── _messages.scss          - Messages island styles.
│   │   ├── _system.scss            - System island styles.
│   │   ├── _power.scss             - Power island and menu styles.
│   │   └── _popup.scss             - Stub popup styles.
│   ├── templates/
│   │   └── windows.yuck.template   - Template for geometry injection.
│   └── scripts/
│       ├── monitor-listener.sh     - Hyprland monitor event listener daemon.
│       ├── resolution-cacher.sh    - Writes monitor resolutions to cache files.
│       ├── resolution-decider.sh   - Reads cache and outputs compact level JSON.
│       ├── resolution-patcher.sh   - Injects pixel values into windows.yuck.
│       ├── battery.sh              - Battery status with desktop auto-hide.
│       ├── network.sh              - Wi-Fi and LAN detection.
│       ├── workspaces.sh           - Hyprland workspace state via socket.
│       ├── music.sh                - MPD and YouTube Music via playerctl.
│       ├── messages.sh             - Discord, Gmail, and Slack unread counts.
│       ├── power.sh                - Power menu actions.
│       ├── icon-patcher.sh         - Fetch and colorize a single Material Icon.
│       ├── icon-installer.sh       - Batch icon setup for all EWW widgets.
│       └── lib/
│           ├── island-resizer.sh   - Island minimum width constants.
│           └── island-renderer.sh  - Compact level to display flag calculator.
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
| Battery presence  | Auto-detected via /sys/class/power_supply.  |
| Monitor count     | Set manually in device.conf.                |
| Device type       | Set manually in device.conf.                |
| Wallpaper path    | Set manually in device.conf.                |
| API tokens        | Set manually in device.conf (git-ignored).  |

device.conf is never committed to git. Copy device.conf.example
and fill in the values for each new machine.

## Responsive bar system

The bar automatically adapts to any monitor resolution.

```
monitor-listener.sh (daemon)
    ├── resolution-cacher.sh      - Caches monitor resolution to ~/.cache/eww/monitor-N.
    └── resolution-patcher.sh     - Injects pixel values into windows.yuck.

defpoll resolution (every 2 seconds)
    └── resolution-decider.sh
        ├── lib/island-resizer.sh  - Island minimum width constants.
        └── lib/island-renderer.sh - Display flag calculator.
```

Compact level thresholds:

| Level | OS          | Wi-Fi          | Date             |
|-------|-------------|----------------|------------------|
| 0     | Icon + text | Icon + SSID    | Full date        |
| 1     | Icon only   | Icon + SSID    | Full date        |
| 2     | Icon only   | Icon only      | Abbreviated date |
| 3     | Icon only   | Icon only      | Time only        |

## Known issues

- `wezterm` (stable) fails to launch on Wayland with Hyprland. Use `wezterm-git` from the AUR instead.
- `eww` is not available in the official Arch repositories or AUR as of 2026. Build from source or install via `yay -S eww` if it becomes available.
