# This fork

This is a personal fork of [`caelestia-dots/shell`](https://github.com/caelestia-dots/shell)
used to make ongoing personal customizations to the shell without losing those changes on
upstream/package updates. The first change was moving the bar from a vertical strip on the
left to a horizontal bar across the top of the screen; more customizations will land on the
same branch over time.

## Where everything lives

-   **Local checkout:** `~/.local/share/caelestia-shell`, branch `custom`
    (branched off tag `v2.3.0` to match the installed `caelestia-shell` AUR package version).
-   **Remotes** (configured on `origin`):
    -   Fetch: `github.com/Al3xDiaz/shell`
    -   Push: both `github.com/Al3xDiaz/shell` **and** `gitlab.com/Al3xDiaz/shell` (a plain
        mirror, kept in sync via `git push`)
-   **`upstream` remote:** `github.com/caelestia-dots/shell` (the original project, used to pull
    in future updates).
-   **Live wiring:** `~/.config/quickshell/caelestia` is a symlink to this checkout. Quickshell
    resolves `-c caelestia` by checking `$XDG_CONFIG_HOME/quickshell/caelestia/shell.qml` before
    falling back to `/etc/xdg/quickshell/caelestia` (the AUR package's copy), so this symlink
    takes priority without needing to uninstall the package — the package still provides the
    native Qt plugin, `caelestia-cli`, and dependencies.
-   `~/.config/caelestia/shell.json` and `~/.config/caelestia/shell-tokens.json` are read
    independently of where the QML source lives, but **this fork does rely on specific values
    in them** — see "Local config not tracked by git" below.

## Reproducing this setup from scratch

```sh
gh repo fork caelestia-dots/shell --clone
git clone https://github.com/<you>/shell.git ~/.local/share/caelestia-shell
cd ~/.local/share/caelestia-shell
git remote add upstream https://github.com/caelestia-dots/shell.git
git checkout -b custom v2.3.0   # match your installed package version

mkdir -p ~/.config/quickshell
ln -s ~/.local/share/caelestia-shell ~/.config/quickshell/caelestia

# reload the shell to pick it up
qs -c caelestia kill
caelestia shell -d
```

To also mirror pushes to GitLab:

```sh
git remote set-url --add --push origin https://github.com/<you>/shell.git
git remote set-url --add --push origin git@gitlab.com:<you>/shell.git
```

## Updating from upstream

```sh
cd ~/.local/share/caelestia-shell
git fetch upstream
git checkout main && git merge upstream/main     # fast-forward, no local commits on main
git checkout custom
git rebase main                                  # resolve conflicts, likely in modules/bar/*
qs -c caelestia kill && caelestia shell -d       # full reload after structural changes
```

## Local config not tracked by git

None of this repo's changes touch `plugin/`, so several things this fork relies on live in
plain user config files instead. Those files live outside this repo's tree (some aren't in any
git repo at all on this machine), so they wouldn't normally survive a reinstall — **backup
copies are kept in [`fork-config/`](fork-config/)** in this repo, alongside notes on what each
value does and where the real, live file actually lives. If you change one of the real files,
copy it back into `fork-config/` and commit, so the backup doesn't drift.

**[`fork-config/shell.json`](fork-config/shell.json)** → real file: `~/.config/caelestia/shell.json`
(native `Config`, not part of this repo). Notable values:
- `bar.entries` — **required** for the wallpaper-cycle button to appear at all (see above);
  `bar.entries` replaces the whole list, this is the full array with `wallpaperCycle` added.
- `bar.popouts.activeWindow: false` — avoids clashing with the Dashboard's hover popup.
- `border.thickness: 9` — the shell's own border/margin accent, reduced ~10% from the default
  `10`. (The much more visible gap around windows is a *separate*, non-shell setting — see
  `fork-config/hypr-variables.lua` below.)

**[`fork-config/shell-tokens.json`](fork-config/shell-tokens.json)** → real file:
`~/.config/caelestia/shell-tokens.json` (native `Tokens`, not part of this repo).
- `sizes.bar.innerWidth: 16` — controls the bar's thickness (default `40`). All the proportional
  icon/font sizing described in "Bar sizing" below is written against this value, so changing it
  further should reflow cleanly, but very small values may need those ratios re-tuned.

**[`fork-config/hypr-variables.lua`](fork-config/hypr-variables.lua)** → real file:
`~/.config/hypr/variables.lua` (separate Hyprland dots config, not this shell at all —
`~/.config/hypr` isn't a git repo on this machine, so this is its only version history).
Notable values (see the file for the full list — everything else is upstream default):
```lua
windowGapsIn        = 5,
windowGapsOut       = 5,   -- was 10
singleWindowGapsOut = 10,  -- was 20 (extra outer gap when only one window is open)
```
Apply with `hyprctl reload` after editing (no shell restart needed, this is Hyprland-side).

## What's changed vs upstream

-   Bar moved from a vertical strip (left edge) to a horizontal bar across the top.
-   All bar sub-widgets (workspaces, clock, tray, status icons, active window, power) reworked
    for a horizontal layout instead of vertical.
-   Hover popouts (status icons, tray) repositioned to work against a horizontal bar.
-   The active-window hover popout is disabled by default (`bar.popouts.activeWindow: false` in
    `shell.json`) since it would otherwise clash with the Dashboard's top-center hover popup.
-   **Wallpaper folder cycling**: new `services/WallpaperCycle.qml` singleton cycles through the
    images in a folder, either on a timer or manually. Since this repo's config is entirely
    native (C++, `plugin/`) and this fork avoids rebuilding that plugin, its own settings
    (folder, interval, shuffle, enabled) live in a separate file:
    `~/.local/state/caelestia/wallpaper-cycle.json` — not in `shell.json`. Configure it via
    Nexus (Wallpaper page → "Auto cycle" section) rather than hand-editing that file.
    -   New bar button: `modules/bar/components/WallpaperButton.qml`, wired in `Bar.qml` as
        entry id `wallpaperCycle`. Left click or scroll up = next, scroll down = previous,
        right click toggles auto-cycle. An in-memory back/forward history (not persisted
        across restarts) makes "previous" actually go back to what was shown before, even
        in `shuffle` mode.
    -   **Requires** adding `wallpaperCycle` to `bar.entries` in `~/.config/caelestia/shell.json`
        for the button to show up — `bar.entries` replaces the whole list, so paste the full
        array (see the example in the upstream README's "Example configuration" section, or the
        one already applied on this machine) with `{"id": "wallpaperCycle", "enabled": true}`
        added wherever you want the button.
    -   `WallpaperCycle` is force-loaded in `modules/ServiceLoader.qml` so the timer runs even if
        the Nexus page is never opened.
-   **Bar sizing**: the bar was shrunk from the default thickness (`sizes.bar.innerWidth: 40`) to
    `16` (see `fork-config/shell-tokens.json`). Several bar sub-components had fixed font/icon
    sizes left over from the horizontal-bar refactor, which clipped or looked disproportionate
    once the bar got much thinner. They were changed to scale off `Tokens.sizes.bar.innerWidth`
    instead, each with its own ratio and a floor (`Math.max(floor, Math.round(innerWidth * ratio))`)
    so they keep shrinking gracefully if `innerWidth` is reduced further, without going illegibly
    small. Current ratios, tuned by eye against `innerWidth: 16`:
    - **General text** (Clock hour:minute/date, ActiveWindow title): `innerWidth * 0.6`
      (`baseFontSize` in `Clock.qml` / `ActiveWindow.qml`).
    - **kbLayout status text**: `innerWidth * 0.67` (`StatusIcons.qml`).
    - **Most icon glyphs** (status icons, tray, lock/bluetooth/battery, calendar): `innerWidth * 0.55`.
    - **ActiveWindow's app-category icon**: `innerWidth * 0.72` — deliberately bigger than the
      general icon ratio, kept independent of the title's text size.
    - **Workspace per-window icons**: `innerWidth * 0.3` — deliberately smaller/secondary
      relative to the main workspace indicator text (`innerWidth * 0.4`).
    - **Whole widgets scaled independently of the bar's own thickness**, so they read as
      distinct from the bar rather than blending in: the **workspaces box** (`Workspaces.qml`
      and everything under `modules/bar/components/workspaces/`) uses `innerWidth * 1.6` instead
      of `innerWidth` directly; the **status-icons box** (`StatusIcons.qml` + `status/*.qml`)
      uses `innerWidth * 1.2`. These multipliers are inlined at every `Tokens.sizes.bar.innerWidth`
      reference in those files rather than introduced as a new token, to keep the diff small —
      if `innerWidth` itself changes, these should still scale proportionally alongside it.

See `git log main..custom` for the full diff against the version this branch is based on.
