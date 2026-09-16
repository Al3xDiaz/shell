# This fork

This is a personal fork of [`caelestia-dots/shell`](https://github.com/caelestia-dots/shell)
used to customize the bar (moved from a vertical strip on the left to a horizontal bar across
the top of the screen) without losing those changes on upstream/package updates.

## Where everything lives

-   **Local checkout:** `~/.local/share/caelestia-shell`, branch `bar-customizations`
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
-   `~/.config/caelestia/shell.json` is untouched by any of this; it's read independently of
    where the QML source lives.

## Reproducing this setup from scratch

```sh
gh repo fork caelestia-dots/shell --clone
git clone https://github.com/<you>/shell.git ~/.local/share/caelestia-shell
cd ~/.local/share/caelestia-shell
git remote add upstream https://github.com/caelestia-dots/shell.git
git checkout -b bar-customizations v2.3.0   # match your installed package version

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
git checkout bar-customizations
git rebase main                                  # resolve conflicts, likely in modules/bar/*
qs -c caelestia kill && caelestia shell -d       # full reload after structural changes
```

## What's changed vs upstream

-   Bar moved from a vertical strip (left edge) to a horizontal bar across the top.
-   All bar sub-widgets (workspaces, clock, tray, status icons, active window, power) reworked
    for a horizontal layout instead of vertical.
-   Hover popouts (status icons, tray) repositioned to work against a horizontal bar.
-   The active-window hover popout is disabled by default (`bar.popouts.activeWindow: false` in
    `shell.json`) since it would otherwise clash with the Dashboard's top-center hover popup.

See `git log main..bar-customizations` for the full diff against the version this branch is
based on.
