# homebrew-s

Personal Homebrew tap for shanberg tools and utilities.

## Setup

```bash
brew tap shanberg/shanberg
```

## Install

After tapping, install formulae by name. Use `--HEAD` for HEAD-only formulae:

```bash
brew install --HEAD shanberg/shanberg/<formula>
```

## Formulae

| Formula | Description |
|---------|-------------|
| [now](Formula/now.rb) | Minimal, terminal-based focus/task tree (TUI + CLI) |
| [maxwell-carmody](Formula/maxwell-carmody.rb) | Self-hosted gateway + deploy CLI (installs from GitHub). For local dev, run `brew install --HEAD ./Formula/maxwell-carmody.rb` after editing the formula to set `head "file://#{Dir.home}/dev/maxwell-carmody", using: :git`. |

## Updating

```bash
brew update
brew upgrade <formula>
```
