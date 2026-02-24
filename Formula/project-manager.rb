# typed: false
# frozen_string_literal: true

# Inlined so the formula works regardless of tap layout; no require_relative.
require "download_strategy"

class GitHubPrivateRepositoryArchiveDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    parse_url_pattern(url)
    set_github_token
    meta[:headers] ||= []
    # Classic PAT (ghp_*) often needs "token "; fine-grained (github_pat_*) uses "Bearer "
    auth = @github_token.start_with?("ghp_") ? "token #{@github_token}" : "Bearer #{@github_token}"
    meta[:headers] << "Authorization: #{auth}"
    meta[:headers] << "Accept: application/vnd.github+json"
    super
    ohai "Downloading from private GitHub (HOMEBREW_GITHUB_API_TOKEN in use)"
  end

  def parse_url_pattern(url)
    unless (match = url.match(%r{https://github\.com/([^/]+)/([^/]+)/(.+)}))
      raise CurlDownloadStrategyError, "Invalid url pattern for GitHub repository archive."
    end

    @owner = match[1]
    @repo = match[2]
    @filepath = match[3]
    @ref = if (m = @filepath.match(%r{refs/heads/(.+)\.tar\.gz}))
      m[1]
    else
      File.basename(@filepath, ".tar.gz")
    end
  end

  # Use API URL so redirect to codeload.github.com is authenticated correctly.
  def download_url
    "https://api.github.com/repos/#{@owner}/#{@repo}/tarball/#{@ref}"
  end

  def resolve_url_basename_time_file_size(url, timeout: nil)
    [download_url, parse_basename(url), nil, nil, nil, false]
  end

  def _fetch(url:, resolved_url:, timeout: nil)
    curl_download download_url, to: temporary_path, timeout:
  rescue ErrorDuringExecution => e
    raise CurlDownloadStrategyError,
          "Private GitHub archive download failed. " \
          "Check token: curl -sI -H 'Authorization: token YOUR_TOKEN' '#{download_url}'"
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
    # API tarball has one top-level dir: owner-repo-sha (not project-manager-main)
    cd Dir.glob("*").find { |f| File.directory?(f) } do
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
