# typed: false
# frozen_string_literal: true

# Release tarball: project-manager-<version>/pm (Swift binary). No Node.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.9.1/project-manager-0.9.1.tar.gz"
  sha256 "f132a448a8d5ffb62f0116f9fb6e8e0e4bcd534fecfa12eb18e9d361fb3e323d"
  version "0.9.1"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  def install
    bin.install "pm"
  end

  test do
    output = shell_output("#{bin}/pm 2>&1", 1)
    assert_match(/Usage: pm/, output)
  end
end
