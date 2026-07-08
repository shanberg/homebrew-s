# frozen_string_literal: true

cask "pm" do
  version "0.9.1"
  sha256 "cafe0b08b7c1fc2e2b07046c1e6af1012faab63a73d35444a37dab8606180d74"

  url "https://github.com/shanberg/project-manager/releases/download/v#{version}/PM-v#{version}.zip"
  name "PM"
  desc "Menubar app for PARA-style project management (Project Manager)"
  homepage "https://github.com/shanberg/project-manager"

  # Apple Silicon only, macOS 13+ — matches the Developer ID / notarized build.
  depends_on arch:  :arm64
  depends_on macos: :ventura

  # The CLI (`pm`) is the companion; not a hard requirement, but they share config.
  app "PM.app"

  uninstall quit: "com.stuarthanberg.pm"

  # Only remove app-owned state on `--zap`. Deliberately NOT touching ~/.config/pm —
  # that config is shared with the `project-manager` CLI formula, which owns it.
  zap trash: [
    "~/Library/Caches/com.stuarthanberg.pm",
    "~/Library/Preferences/com.stuarthanberg.pm.plist",
    "~/Library/Saved Application State/com.stuarthanberg.pm.savedState",
  ]
end
