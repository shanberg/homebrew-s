# typed: false
# frozen_string_literal: true

# Release tarball: project-manager-<version>/pm (Swift binary). No Node.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.48.0/project-manager-0.48.0.tar.gz"
  sha256 "9a20aa1e8cdea3cdc517b3951b3f1a6d7af259ef91094411325722a029369126"
  version "0.48.0"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  def install
    bin.install "pm"
  end

  test do
    output = shell_output("#{bin}/pm 2>&1", 1)
    assert_match(/Usage: pm/, output)
  end
end
