# typed: false
# frozen_string_literal: true

# Inlined so the formula works regardless of tap layout; no require_relative.
require "download_strategy"
require "json"

# Install runs in a sandbox with stripped ENV; download runs with user ENV. Persist token
# from download so install can read it (then we delete the file). Constant so strategy sees it in isolated namespace.
PROJECT_MANAGER_TOKEN_FILE = "#{ENV["HOMEBREW_CACHE"]}/.project-manager-github-token".freeze

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
    gh_path = "#{HOMEBREW_PREFIX}/opt/gh/bin/gh"
    @github_token = `"#{gh_path}" auth token 2>/dev/null`.to_s.strip if @github_token.empty? && File.exist?(gh_path)
    raise CurlDownloadStrategyError, "No GitHub token. Set HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN (gh is not in PATH in the build env)." if @github_token.empty?
  end
end

# Deterministic tarball from release asset (git archive). Private repos require the
# releases API (GET .../releases/assets/ID); the browser download URL does not accept Auth.
class GitHubPrivateReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    @release_url = url
    set_github_token
    parse_release_url
    meta[:headers] ||= []
    super
    ohai "Downloading from private GitHub release (HOMEBREW_GITHUB_API_TOKEN in use)"
  end

  def parse_release_url
    m = @release_url.match(%r{github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)$})
    raise CurlDownloadStrategyError, "Invalid release URL: #{@release_url}" unless m
    @owner, @repo, @tag, @asset_name = m[1], m[2], m[3], m[4]
  end

  def download_url
    @release_url
  end

  def resolve_url_basename_time_file_size(url, timeout: nil)
    [@release_url, File.basename(@release_url.split("?").first), nil, nil, nil, false]
  end

  def _fetch(url:, resolved_url:, timeout: nil)
    auth = @github_token.start_with?("ghp_") ? "token #{@github_token}" : "Bearer #{@github_token}"
    # Get release by tag to find asset id (required for private repo asset download)
    release_json = `curl -sL -H "Authorization: #{auth}" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}"`.strip
    release = JSON.parse(release_json)
    asset = release["assets"]&.find { |a| a["name"] == @asset_name }
    raise CurlDownloadStrategyError, "Asset #{@asset_name} not found in release #{@tag}." unless asset
    asset_url = "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset['id']}"
    curl_download asset_url,
      "-L", "--header", "Authorization: #{auth}", "--header", "Accept: application/octet-stream",
      to: temporary_path, timeout:
  rescue JSON::ParserError, KeyError => e
    raise CurlDownloadStrategyError, "Private GitHub release download failed: #{e.message}"
  rescue ErrorDuringExecution => e
    raise CurlDownloadStrategyError,
          "Private GitHub release download failed. Ensure token has repo scope and release #{@tag} exists."
  end

  def set_github_token
    @github_token = (ENV["HOMEBREW_GITHUB_API_TOKEN"] || ENV["GITHUB_TOKEN"]).to_s.strip
    gh_path = "#{HOMEBREW_PREFIX}/opt/gh/bin/gh"
    @github_token = `"#{gh_path}" auth token 2>/dev/null`.to_s.strip if @github_token.empty? && File.exist?(gh_path)
    raise CurlDownloadStrategyError, "No GitHub token. Set HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN (gh is not in PATH in the build env)." if @github_token.empty?
    File.write(PROJECT_MANAGER_TOKEN_FILE, @github_token)
  end
end

class ProjectManager < Formula
  desc "CLI for PARA-style project creation with domain-based numbering"
  homepage "https://github.com/shanberg/project-manager"
  # Release asset = git archive tarball (deterministic sha256). API tarball varies by request.
  url "https://github.com/shanberg/project-manager/releases/download/v0.1.11/project-manager-0.1.11.tar.gz",
      using: GitHubPrivateReleaseDownloadStrategy
  sha256 "d0a937be29626dcb622e9b98a5daf7abf52828cd2ce12aa1ec3b08510069f793"
  version "0.1.11"
  head "https://github.com/shanberg/project-manager.git", branch: "main"

  depends_on "node"

  def install
    token = nil
    token = File.read(PROJECT_MANAGER_TOKEN_FILE).strip if File.exist?(PROJECT_MANAGER_TOKEN_FILE)
    File.delete(PROJECT_MANAGER_TOKEN_FILE) if File.exist?(PROJECT_MANAGER_TOKEN_FILE)
    token = (ENV["HOMEBREW_GITHUB_API_TOKEN"] || ENV["GITHUB_TOKEN"]).to_s.strip if token.to_s.empty?
    if token.to_s.empty?
      gh_path = "#{HOMEBREW_PREFIX}/opt/gh/bin/gh"
      token = `"#{gh_path}" auth token 2>/dev/null`.to_s.strip if File.exist?(gh_path)
    end
    odie "No GitHub token. Set HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN (gh is not in PATH in the build env)." if token.to_s.empty?
    # Homebrew stages the tarball and chdirs into its single top-level dir (project-manager-VERSION) before calling install; buildpath is that dir.
    cd buildpath do
      (Pathname.pwd/".npmrc").write("@shanberg:registry=https://npm.pkg.github.com/\n//npm.pkg.github.com/:_authToken=#{token}\n")
      ENV["npm_config_cache"] = "#{HOMEBREW_CACHE}/npm_cache"
      system "npm", "install", "--ignore-scripts"
      system "npm", "run", "build"
      libexec.install "dist", "node_modules", "package.json"
    end
    (bin/"pm").write_env_script libexec/"dist/cli.js", NODE_PATH: libexec/"node_modules"
  end

  test do
    assert_match(/PARA-style project creation/, shell_output("#{bin}/pm --help"))
  end
end
