# typed: false
# frozen_string_literal: true

# Release tarball: project-manager-<version>/pm (Swift binary). No Node.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.16.0/project-manager-0.16.0.tar.gz"
  sha256 "36d45faf6717a2906098e6ad9c5949c2ee9d89807c1a5c663e67c658820f373c"
  version "0.16.0"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  def install
    bin.install "pm"
  end

  test do
    output = shell_output("#{bin}/pm 2>&1", 1)
    assert_match(/Usage: pm/, output)
  end
end
