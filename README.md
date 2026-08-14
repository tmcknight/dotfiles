# Dotfiles

Everything I need to go from a fresh Mac, Linux box, or Windows box to fully set up in one command.

## macOS / Linux

On a fresh Mac or Linux box, run:

```bash
curl -fsSL -o /tmp/install.sh https://raw.githubusercontent.com/tmcknight/dotfiles/main/install.sh && bash /tmp/install.sh
```

`install.sh` clones this repo to `~/Developer/dotfiles` (or pulls it if already
present), then runs the setup script for the detected OS. Set `DOTFILES_DIR` to
clone somewhere else.

Config files are **symlinked** out of the clone rather than copied, so editing a
file in `~/Developer/dotfiles` takes effect immediately — no re-run needed.
Re-running setup is safe and idempotent. Any pre-existing file is backed up
alongside itself with a timestamp (`~/.zshrc.20260814-120000.backup`) before
being replaced.

To update later:

```bash
git -C ~/Developer/dotfiles pull
```

### macOS

The setup script will:

1. Set default shell to zsh
2. Create `~/Developer` directory
3. Install [Homebrew](https://brew.sh) (+ Xcode Command Line Tools if not already installed)
4. Install all packages and casks from the [Brewfile](macos/Brewfile)
5. Link the [.zshrc](shared/.zshrc), [.aliases](shared/.aliases) and [.gitconfig](shared/.gitconfig)
6. Link the [oh-my-posh theme](shared/theme.omp.json) to `~/.config/oh-my-posh/` and the
   [Claude Code statusline](shared/claude-statusline.sh) to `~/.claude/`
7. Link the [Ghostty config](macos/ghostty.config) to `~/Library/Application Support/com.mitchellh.ghostty/`
8. Set macOS system preferences (Finder settings)

### Linux (Debian/Ubuntu)

Debian/Ubuntu only — the script exits early if `apt-get` is not present.

The setup script will:

1. Install zsh (+ zsh-autosuggestions) and set it as the default shell
2. Create `~/Developer` directory
3. Install [eza](https://github.com/eza-community/eza) via official apt repo
4. Install [GitHub CLI](https://cli.github.com/)
5. Install [Node.js](https://nodejs.org/) LTS via NodeSource
6. Install [oh-my-posh](https://ohmyposh.dev/)
7. Link the [.zshrc](shared/.zshrc), [.aliases](shared/.aliases), [.gitconfig](shared/.gitconfig),
   [oh-my-posh theme](shared/theme.omp.json) and [Claude Code statusline](shared/claude-statusline.sh)
   (installing `jq`, which the statusline needs)

## Windows

```pwsh
# run configuration script to setup Windows environment
Unblock-File -Path .\windows\configure.ps1
.\windows\configure.ps1
```

Run it from the repo root. It installs the winget packages, the Meslo nerd font,
the Windows Terminal settings, the [oh-my-posh theme](shared/theme.omp.json) to
`~\.config\oh-my-posh\`, and the PowerShell profile.

## git config

[shared/.gitconfig](shared/.gitconfig) holds portable settings only. Identity,
signing keys and credential helpers belong in `~/.gitconfig.local`, which is not
tracked — it is pulled in by an `[include]` at the end of the tracked file, and
anything set there overrides it.

On first run, setup moves an existing `~/.gitconfig` to `~/.gitconfig.local`
automatically, so signing and identity keep working. If `~/.gitconfig.local`
already exists it is left alone, and the old `~/.gitconfig` is backed up instead.

## Claude Code statusline

[shared/claude-statusline.sh](shared/claude-statusline.sh) renders a two-line
status line mirroring the oh-my-posh theme. It requires `jq`. To enable it, add
this to `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
```

## Development

CI ([.github/workflows/lint.yml](.github/workflows/lint.yml)) runs `bash -n` and
`shellcheck` over the shell scripts, parses every `.ps1`, and validates the JSON
configs. To run the shell checks locally:

```bash
shellcheck -x install.sh macos/setup.sh linux/setup.sh shared/lib.sh shared/claude-statusline.sh
```

Shared helpers used by both setup scripts live in [shared/lib.sh](shared/lib.sh).
