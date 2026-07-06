# frozen_string_literal: true

cask "pm" do
  version "0.8.0"
  sha256 "4e1c0dbf2f59ed81bdd89979dcc42c16e99d32419d3696141ee7be3e9b568880"

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
