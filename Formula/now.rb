# typed: false
# frozen_string_literal: true

class Now < Formula
  desc "Minimal, opinionated, terminal-based tool for reminding you what to focus on"
  homepage "https://github.com/shanberg/now"
  head "file://#{Dir.home}/dev/now", using: :git

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
