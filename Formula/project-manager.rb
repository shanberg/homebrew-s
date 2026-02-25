# typed: false
# frozen_string_literal: true

# Release tarball is bundled (dist + node_modules + templates); no npm install needed.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.1.12/project-manager-0.1.12.tar.gz"
  sha256 "2550272730c7f95253a597a0f8a0e9bc2eb69589f9cafa79f7a49a3539b80b84"
  version "0.1.12"
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
