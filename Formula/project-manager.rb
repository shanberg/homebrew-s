# typed: false
# frozen_string_literal: true

class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/archive/refs/heads/main.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  version "0.1.0"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  depends_on "node"

  def install
    cd "project-manager-main" do
      ENV["npm_config_cache"] = "#{HOMEBREW_CACHE}/npm_cache"
      system "npm", "install"
      system "npm", "run", "build"
      libexec.install "dist", "node_modules", "package.json"
    end
    (bin/"pm").write_env_script libexec/"dist/cli.js", NODE_PATH: libexec/"node_modules"
  end

  test do
    assert_match(/PARA-style project creation/, shell_output("#{bin}/pm --help"))
  end
end
