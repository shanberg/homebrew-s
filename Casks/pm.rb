# frozen_string_literal: true

cask "pm" do
  version "0.12.1"
  sha256 "3dba653ea7ed298ada5847ce46bfc736c0ed89fd2f70b69918e262b295c4c8ed"

  url "https://github.com/shanberg/project-manager/releases/download/v#{version}/PM-v#{version}.zip"
  name "PM"
  desc "Menubar app for PARA-style project management (Project Manager)"
  homepage "https://github.com/shanberg/project-manager"

  # Apple Silicon only, macOS 26+ — matches the app's deployment target and the
  # Developer ID / notarized build.
  depends_on arch:  :arm64
  depends_on macos: :tahoe

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
