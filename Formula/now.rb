# typed: false
# frozen_string_literal: true

class Now < Formula
  desc "Minimal, opinionated, terminal-based tool for reminding you what to focus on"
  homepage "https://github.com/shanberg/now"
  url "https://github.com/shanberg/now/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  version "1.0.0"
  head "https://github.com/shanberg/now.git", branch: "main"
  # After releasing: curl -sL https://github.com/shanberg/now/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256

  depends_on "deno" => :build

  def install
    system "deno", "compile",
           "--allow-read", "--allow-write", "--allow-env",
           "--output", "dist/now", "src/index.ts"
    bin.install "dist/now"
  end

  test do
    assert_match(/requires/, shell_output("#{bin}/now edit 2>&1", 1))
  end
end
