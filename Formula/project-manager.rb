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
    # refs/heads/main or refs/tags/v0.1.0 → ref for API tarball
    @ref = if (m = @filepath.match(%r{refs/(?:heads|tags)/(.+)\.tar\.gz}))
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
    @github_token = (ENV["HOMEBREW_GITHUB_API_TOKEN"] || ENV["GITHUB_TOKEN"]).to_s.strip
    @github_token = `gh auth token 2>/dev/null`.to_s.strip if @github_token.empty? && system("which gh >/dev/null 2>&1")
    raise CurlDownloadStrategyError, "No GitHub token. Run 'gh auth login' or set HOMEBREW_GITHUB_API_TOKEN / GITHUB_TOKEN." if @github_token.empty?
  end
end

# Deterministic tarball from release asset (git archive); avoids API tarball checksum variance.
class GitHubPrivateReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    @release_url = url
    set_github_token
    meta[:headers] ||= []
    auth = @github_token.start_with?("ghp_") ? "token #{@github_token}" : "Bearer #{@github_token}"
    meta[:headers] << "Authorization: #{auth}"
    meta[:headers] << "Accept: application/octet-stream"
    super
    ohai "Downloading from private GitHub release (HOMEBREW_GITHUB_API_TOKEN in use)"
  end

  def download_url
    @release_url
  end

  def resolve_url_basename_time_file_size(url, timeout: nil)
    [@release_url, File.basename(@release_url.split("?").first), nil, nil, nil, false]
  end

  def _fetch(url:, resolved_url:, timeout: nil)
    curl_download @release_url, to: temporary_path, timeout:
  rescue ErrorDuringExecution => e
    raise CurlDownloadStrategyError,
          "Private GitHub release download failed. Set HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN and ensure the token has repo scope."
  end

  def set_github_token
    @github_token = (ENV["HOMEBREW_GITHUB_API_TOKEN"] || ENV["GITHUB_TOKEN"]).to_s.strip
    @github_token = `gh auth token 2>/dev/null`.to_s.strip if @github_token.empty? && system("which gh >/dev/null 2>&1")
    raise CurlDownloadStrategyError, "No GitHub token. Run 'gh auth login' or set HOMEBREW_GITHUB_API_TOKEN / GITHUB_TOKEN." if @github_token.empty?
  end
end

class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  # Release asset = git archive tarball (deterministic sha256). API tarball varies by request.
  url "https://github.com/shanberg/project-manager/releases/download/v0.1.6/project-manager-0.1.6.tar.gz",
      using: GitHubPrivateReleaseDownloadStrategy
  sha256 "7762ea12522c3f410de2affde8a732f796861f7e9ded86f3060252f496d984bf"
  version "0.1.6"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  depends_on "node"

  def install
    token = (ENV["HOMEBREW_GITHUB_API_TOKEN"] || ENV["GITHUB_TOKEN"]).to_s.strip
    token = `gh auth token 2>/dev/null`.to_s.strip if token.empty? && system("which gh >/dev/null 2>&1")
    odie "No GitHub token. Run 'gh auth login' or set HOMEBREW_GITHUB_API_TOKEN / GITHUB_TOKEN." if token.empty?
    # Tarball has one top-level dir: project-manager-VERSION (from git archive)
    cd Dir.glob("*").find { |f| File.directory?(f) } do
      (Pathname.pwd/".npmrc").write("//npm.pkg.github.com/:_authToken=#{token}\n")
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
