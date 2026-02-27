# typed: false
# frozen_string_literal: true

# Release tarball: project-manager-<version>/pm (Swift binary). No Node.
class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/releases/download/v0.2.1/project-manager-0.2.1.tar.gz"
  sha256 "4a9f72e7dd07049b9ee6172a3849abf0f3a458eb07c34a8ca9d1cc159fb82cf9"
  version "0.2.1"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  def install
    bin.install "pm"
  end

  test do
    assert_match(/PARA-style project creation|domain-based numbering/, shell_output("#{bin}/pm --help"))
  end
end
