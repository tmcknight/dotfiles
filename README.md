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
4. Trust the third-party taps the [Brewfile](macos/Brewfile) declares, since Homebrew will
   not load formulae or casks from an untrusted tap
5. Install all packages and casks from the [Brewfile](macos/Brewfile)
6. Install the Node LTS via [fnm](https://github.com/Schniz/fnm) and set it as the default
7. Link the [.zshrc](shared/.zshrc), [.aliases](shared/.aliases), [.gitconfig](shared/.gitconfig)
   and the [unattended signing helpers](shared/git-signing.sh)
8. Link the [oh-my-posh theme](shared/theme.omp.json) to `~/.config/oh-my-posh/` and the
   [Claude Code statusline](shared/claude-statusline.sh) to `~/.claude/`
9. Link the [Ghostty config](macos/ghostty.config) to `~/Library/Application Support/com.mitchellh.ghostty/`
10. Set macOS system preferences (Finder settings)

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
   [unattended signing helpers](shared/git-signing.sh), [oh-my-posh theme](shared/theme.omp.json)
   and [Claude Code statusline](shared/claude-statusline.sh) (installing `jq`, which the
   statusline needs)

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

### Per-org commit identity

Personal and work clones sit side by side under `~/Developer`, so a `gitdir:`
rule cannot tell them apart. `~/.gitconfig.local` keys the identity off the
repo's **remote URL** instead, with `includeIf "hasconfig:remote.*.url:"`
(git 2.36+):

```gitconfig
[includeIf "hasconfig:remote.*.url:https://github.com/<org>/**"]
	path = ~/.gitconfig.<org>
```

One block per URL form — `https://` and `git@` share no prefix, and the match is
case-sensitive. Check what a repo resolved to with `git config --get user.email`.

A repo with no remote yet (fresh `git init`, before `git remote add`) matches
nothing and uses the default identity. Add the remote before the first commit,
or fix it after with `git commit --amend --reset-author`.

Every identity signs with the same key, so each one needs a line — or a slot on
a shared comma-separated line — in the `gpg.ssh.allowedSignersFile`. Git looks
the signer up by committer email, and an email that is missing there shows as
signed-by-an-unknown-key rather than as you.

### Unattended signing

[shared/git-signing.sh](shared/git-signing.sh) switches git to an on-disk
signing key for the current shell, using `GIT_CONFIG_*` environment overrides
that outrank every config file. It exists for the two cases an interactive
signing agent cannot serve: an agent session with nobody at the keyboard, and a
remote host where the agent's binary is not installed and signing fails outright.

```bash
git-signing-on       # sign with $GIT_SIGNING_KEY, no prompt, this shell only
git-signing-off      # hand signing back to the configured default
git-signing-status   # report which is in effect, and the resolved identity
```

Setting `GIT_SIGNING_UNATTENDED=1` in the environment before the shell starts
turns it on with no command to type — the hook for agent runners and remote
hosts. Nothing is written to `~/.gitconfig.local`, so a shell that has not opted
in signs interactively as before.

Getting a key onto the machine is deliberately not in this repo: that is the
half that names a secret store. Define `git-signing-export` in
`~/.git-signing.local.sh`, which is untracked and sourced automatically if
present.

> A key reachable without a prompt is a key an attacker can use without a
> prompt, and its signatures are indistinguishable from the interactive ones —
> the commit log cannot tell you which commits were unattended. Put a key on a
> machine only if you would trust that machine with your identity, and revoke it
> on GitHub if the machine is lost.

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
shellcheck -x install.sh macos/setup.sh linux/setup.sh shared/lib.sh shared/claude-statusline.sh shared/git-signing.sh
```

Shared helpers used by both setup scripts live in [shared/lib.sh](shared/lib.sh).
