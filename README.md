# homebrew-shanberg

Personal Homebrew tap for shanberg tools and utilities.

## Setup

```bash
brew tap shanberg/shanberg
```

## Install

After tapping, install formulae by name. These formulae are **HEAD-only** and point at local dev directories; use `--HEAD`:

```bash
brew install --HEAD shanberg/shanberg/<formula>
```

## Formulae

| Formula | Description |
|---------|-------------|
| [now](Formula/now.rb) | Minimal, terminal-based focus/task tree (TUI + CLI) |
| [maxwell-carmody](Formula/maxwell-carmody.rb) | Self-hosted gateway + deploy CLI |

## Updating

```bash
brew update
brew upgrade <formula>
```
