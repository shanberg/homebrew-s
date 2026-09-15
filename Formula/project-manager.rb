# typed: false
# frozen_string_literal: true

# Release tarball: project-manager-<version>/pm (Swift binary). No Node.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.41.0/project-manager-0.41.0.tar.gz"
  sha256 "d6ec4bd78e7e85fdfe4e7eedbe9a53c7890064eb4ac8f3f196d64c8e22185e40"
  version "0.41.0"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  def install
    bin.install "pm"
  end

  test do
    output = shell_output("#{bin}/pm 2>&1", 1)
    assert_match(/Usage: pm/, output)
  end
end
