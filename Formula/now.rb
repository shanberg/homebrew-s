# typed: false
# frozen_string_literal: true

class Now < Formula
  desc "Minimal, opinionated, terminal-based tool for reminding you what to focus on"
  homepage "https://github.com/shanberg/now"
  url "https://github.com/shanberg/now/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "d5558cd419c8d46bdc958064cb97f963d1ea793866414c025906ec15033512ed"
  version "1.0.0"
  head "https://github.com/shanberg/now.git", branch: "main"

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
