# typed: false
# frozen_string_literal: true

# Release tarball is bundled (dist + node_modules + templates); no npm install needed.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.1.13/project-manager-0.1.13.tar.gz"
  sha256 "53612f6f55fdad3465b377202d7bce0949ce32fdd5dc4d86a87b0330597801de"
  version "0.1.13"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  depends_on "node"

  def install
    libexec.install "dist", "node_modules", "package.json", "templates"
    (bin/"pm").write_env_script libexec/"dist/cli.js", NODE_PATH: libexec/"node_modules"
  end

  test do
    assert_match(/PARA-style project creation/, shell_output("#{bin}/pm --help"))
  end
end
