# typed: false
# frozen_string_literal: true

# Inlined so the formula works regardless of tap layout; no require_relative.
require "download_strategy"

class GitHubPrivateRepositoryArchiveDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    parse_url_pattern
    set_github_token
    ohai "Downloading from private GitHub (HOMEBREW_GITHUB_API_TOKEN in use)"
  end

  def parse_url_pattern
    unless (match = url.match(%r{https://github\.com/([^/]+)/([^/]+)/(.+)}))
      raise CurlDownloadStrategyError, "Invalid url pattern for GitHub repository archive."
    end

    @owner = match[1]
    @repo = match[2]
    @filepath = match[3]
  end

  def download_url
    "https://#{@github_token}@github.com/#{@owner}/#{@repo}/#{@filepath}"
  end

  def resolve_url_basename_time_file_size(url, timeout: nil)
    [download_url, parse_basename(url), nil, nil, nil, false]
  end

  def _fetch(url:, resolved_url:, timeout: nil)
    curl_download download_url, to: temporary_path, timeout:
  end

  def set_github_token
    @github_token = ENV["HOMEBREW_GITHUB_API_TOKEN"]
    raise CurlDownloadStrategyError, "HOMEBREW_GITHUB_API_TOKEN is required for private repos." if @github_token.to_s.empty?
  end
end

class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  url "https://github.com/shanberg/project-manager/archive/refs/heads/main.tar.gz",
      using: GitHubPrivateRepositoryArchiveDownloadStrategy
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  version "0.1.0"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  depends_on "node"

  def install
    cd "project-manager-main" do
      ENV["npm_config_cache"] = "#{HOMEBREW_CACHE}/npm_cache"
      system "npm", "install"
      system "npm", "run", "build"
      libexec.install "dist", "node_modules", "package.json"
    end
    (bin/"pm").write_env_script libexec/"dist/cli.js", NODE_PATH: libexec/"node_modules"
  end

  test do
    assert_match(/PARA-style project creation/, shell_output("#{bin}/pm --help"))
  end
end
