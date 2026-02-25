# typed: false
# frozen_string_literal: true

# Release tarball is bundled (dist + node_modules + templates); no npm install needed.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.1.14/project-manager-0.1.14.tar.gz"
  sha256 "8e7e8eae57a2a5808b6c650893d00f125c95082c5ad93659b2f004b93e2a368b"
  version "0.1.14"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  depends_on "node"

  def install
    libexec.install "dist", "node_modules", "package.json", "templates"
    (bin/"pm").write_env_script libexec/"dist/cli.js", NODE_PATH: libexec/"node_modules"
  end

  def caveats
    <<~EOS
      Raycast extension (optional):
        1. Download project-manager-extension-#{version}.zip from
           #{homepage}/releases
        2. Unzip to e.g. ~/project-manager
        3. In Terminal: cd ~/project-manager/raycast-extension && npm run dev
           (imports the extension into Raycast; leave "pm CLI Path" empty)
    EOS
  end

  test do
    assert_match(/PARA-style project creation/, shell_output("#{bin}/pm --help"))
  end
end
