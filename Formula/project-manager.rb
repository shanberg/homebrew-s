# typed: false
# frozen_string_literal: true

# Tap, project-manager repo/releases, and @shanberg/project-schema are public — no token required.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.1.12/project-manager-0.1.12.tar.gz"
  sha256 "bee1655dc9b42e50e11bcacddfd752fae218c1ee7e8c3ed43d6a60f30749d366"
  version "0.1.12"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  depends_on "node"

  def install
    cd buildpath do
      ENV["npm_config_cache"] = "#{HOMEBREW_CACHE}/npm_cache"
      system "npm", "install", "--ignore-scripts"
      system "npm", "run", "build"
      libexec.install "dist", "node_modules", "package.json", "templates"
    end
    (bin/"pm").write_env_script libexec/"dist/cli.js", NODE_PATH: libexec/"node_modules"
  end

  test do
    assert_match(/PARA-style project creation/, shell_output("#{bin}/pm --help"))
  end
end
