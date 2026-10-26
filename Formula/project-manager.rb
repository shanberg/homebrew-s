# typed: false
# frozen_string_literal: true

# Release tarball: project-manager-<version>/pm (Swift binary). No Node.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.52.1/project-manager-0.52.1.tar.gz"
  sha256 "8cc60e5c6457402cc7a3ddd2007c23f3f34ef41e8597de041a9276ccf37782d9"
  version "0.52.1"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  def install
    bin.install "pm"
  end

  test do
    output = shell_output("#{bin}/pm 2>&1", 1)
    assert_match(/Usage: pm/, output)
  end
end
