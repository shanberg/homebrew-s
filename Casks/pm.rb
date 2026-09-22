# frozen_string_literal: true

cask "pm" do
  version "0.47.0"
  sha256 "fb05f2890e5eb147cd4d062b7404c3aeefe034c41b9e0b7505aaabdf1f27812c"

  url "https://github.com/shanberg/project-manager/releases/download/v#{version}/Folio-v#{version}.zip"
  name "Folio"
  desc "Menubar app for PARA-style project management (Project Manager)"
  homepage "https://github.com/shanberg/project-manager"

  # Apple Silicon only, macOS 26+ — matches the app's deployment target and the
  # Developer ID / notarized build.
  depends_on arch:  :arm64
  depends_on macos: :tahoe

  # The CLI (`pm`) is the companion; not a hard requirement, but they share config.
  app "Folio.app"

  uninstall quit: "com.stuarthanberg.pm"

  # Only remove app-owned state on `--zap`. Deliberately NOT touching ~/.config/pm —
  # that config is shared with the `project-manager` CLI formula, which owns it.
  #
  # ~/Library/WebKit holds the browsing session behind canvas web cards: the cookies and local
  # storage for every site signed into from a card. It is the most personal thing the app keeps,
  # and by far the largest, so leaving it behind on a zap would be the wrong way round.
  zap trash: [
    "~/Library/Application Support/com.stuarthanberg.pm",
    "~/Library/Caches/com.stuarthanberg.pm",
    "~/Library/HTTPStorages/com.stuarthanberg.pm",
    "~/Library/HTTPStorages/com.stuarthanberg.pm.binarycookies",
    "~/Library/Preferences/com.stuarthanberg.pm.plist",
    "~/Library/Saved Application State/com.stuarthanberg.pm.savedState",
    "~/Library/WebKit/com.stuarthanberg.pm",
  ]
end
