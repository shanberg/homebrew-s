# typed: false
# frozen_string_literal: true

class MaxwellCarmody < Formula
  desc "Multi-application architecture for self-hosted services (deploy, gateway, db, validate CLIs)"
  homepage "https://github.com/shanberg/maxwell-carmody"
  head "file://#{Dir.home}/dev/maxwell-carmody", using: :git

  depends_on "node" => :build
  depends_on "pnpm" => :build

  def install
    system "cp", "-R", "#{buildpath}/.", libexec
    system "pnpm", "install", :dir => libexec
    (bin/"deploy").write <<~EOS
      #!/bin/sh
      exec pnpm -C "#{libexec}" exec deploy "$@"
    EOS
    (bin/"gateway").write <<~EOS
      #!/bin/sh
      exec pnpm -C "#{libexec}" run gateway "$@"
    EOS
    (bin/"db").write <<~EOS
      #!/bin/sh
      exec pnpm -C "#{libexec}" run db "$@"
    EOS
    (bin/"validate").write <<~EOS
      #!/bin/sh
      exec pnpm -C "#{libexec}" exec validate "$@"
    EOS
    [bin/"deploy", bin/"gateway", bin/"db", bin/"validate"].each { |f| chmod 0755, f }
  end

  test do
    assert_match(/deploy/, shell_output("#{bin}/deploy --help 2>&1"))
    assert_match(/Usage: gateway/, shell_output("#{bin}/gateway 2>&1"))
    assert_match(/Usage: db/, shell_output("#{bin}/db 2>&1"))
    assert_match(/validate/, shell_output("#{bin}/validate --help 2>&1"))
  end
end
