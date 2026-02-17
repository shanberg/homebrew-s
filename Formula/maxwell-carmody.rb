# Reference Homebrew formula for the Maxwell Carmody deploy CLI and agent.
# Copy this to your tap repo (e.g. homebrew-s/Formula/maxwell-carmody.rb).
#
# Primary command: mc (with deploy kept for backward compatibility)
#   mc agent          - start the deploy agent
#   mc deploy <target>   - trigger deployment (targets from .deployment.json, e.g. staging-maxwellcarmody)
#   mc status [target]  - show deployment state
#   mc logs <id>      - show deployment logs
# See docs/deployment/08-target-model-simplified.md.
#
# Build: Your tap will need to build the monorepo (pnpm install, build deployment
# package and its workspace deps) and then expose the CLI. The deployment
# package bin is at packages/deployment/bin/deploy.js (run with node against
# built dist/ or with tsx against src/). Install both "mc" and "deploy" as
# the same binary so `mc deploy <target>` and `deploy deploy <target>` both work.
#
# Trigger: When HOMEBREW_MC_TRIGGER_DEPLOY=1, post_install should run
# scripts/deployment/trigger-deploy-after-brew.sh <commit> [env].
# Pass the installed commit (e.g. from git rev-parse HEAD when building from
# git, or set HOMEBREW_MC_COMMIT in the formula). Default env is staging
# (override with HOMEBREW_MC_DEPLOY_ENV).

class MaxwellCarmody < Formula
  desc "Deploy CLI and agent for Maxwell Carmody"
  homepage "https://github.com/shanberg/home-services"
  url "https://github.com/shanberg/home-services/archive/fce266c8029a55a049e7e545d9e1acb57008b516.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"
  version "1.0.0"

  # Bottles: build on your machine, host on GitHub Releases. See HOMEBREW-FORMULA.md "Bottles (GitHub Releases)".
  # Run: brew install --build-bottle <formula> && brew bottle <formula>
  # Create a release with tag maxwell-carmody-<version>, upload the .bottle.tar.gz, then replace this block
  # (including root_url and all sha256 lines) with the output from brew bottle so the server can pour instead of building.
  bottle do
    root_url "https://github.com/shanberg/homebrew-s/releases/download/maxwell-carmody-1.0.0"
    rebuild 0
    sha256 arm64_sonoma: "0000000000000000000000000000000000000000000000000000000000000000"
  end

  depends_on "git"
  depends_on "node"
  depends_on "pnpm" => :build

  # Default path for install log; override with HOMEBREW_MC_INSTALL_LOG. Rotated to .prev each install.
  def install_log_path
    ENV["HOMEBREW_MC_INSTALL_LOG"].to_s != "" ? ENV["HOMEBREW_MC_INSTALL_LOG"] : "/tmp/maxwell-carmody-install.log"
  end

  # Run in libexec with stdin closed so no subprocess can block waiting for input (e.g. over SSH).
  # Install output is always teed to install_log_path; full log available after install (tail -f may lag due to pipe buffering).
  # When env_hash is given, inject exports into the shell so pnpm/turbo see PNPM_WORKERS, NODE_OPTIONS, etc. (avoids passing a Hash to system() which can break under Homebrew's Ruby).
  def run_no_stdin(*cmd, env_hash: nil)
    cmd_str = cmd.map { |c| Shellwords.escape(c) }.join(" ")
    log = install_log_path
    inner = "exec 0</dev/null; ( #{cmd_str} ) 2>&1 | tee #{Shellwords.escape(log)}; exit \\${PIPESTATUS[0]}"
    if env_hash && !env_hash.empty?
      exports = env_hash.map { |k, v| "#{k}=#{Shellwords.escape(v.to_s)}" }.join(" ")
      inner = "export #{exports}; #{inner}"
    end
    system "bash", "-c", inner, :dir => libexec
  end

  # Env vars that must reach pnpm and turbo to limit workers and memory. Our defaults override ENV so Homebrew/user env cannot weaken safeguards (e.g. PNPM_WORKERS or NODE_OPTIONS).
  def pnpm_env
    ENV.to_h.merge(
      "CI" => "1",
      "npm_config_yes" => "true",
      "TURBO_CI" => "1",
      "TURBO_CONCURRENCY" => "1",
      "NODE_OPTIONS" => "--max-old-space-size=4096",
      "PNPM_WORKERS" => "999",
    )
  end

  def install
    # Example: build monorepo and install CLI.
    # Adapt to your tap's strategy (e.g. pre-built tarball, or full build).
    # Cap Node heap and concurrency so install does not exhaust system memory.
    check_script = buildpath/"scripts/deployment/ensure-node-memory-limit.sh"
    if check_script.exist?
      system pnpm_env, "bash", check_script.to_s, "--check"
    end
    # Limit concurrency so total memory stays bounded (one main process + one child at a time).
    system pnpm_env, "pnpm", "install", "--frozen-lockfile", "--child-concurrency", "1"
    system pnpm_env, "pnpm", "--filter", "@mc/deployment", "run", "build", "--workspace-concurrency=1"

    # Build deployment package (and its workspace deps). Then install the built
    # package into libexec. The repo's bin/deploy.js imports from src/ (for tsx);
    # for node we use a wrapper that imports from dist/cli/index.js.
    pkg_dir = buildpath/"packages/deployment"
    libexec.install pkg_dir/"dist", pkg_dir/"package.json", pkg_dir/"docker-apps"
    # Copy workspace packages and node_modules so @mc/* resolve at runtime.
    # (Alternatively your tap can use a pre-built tarball that includes node_modules.)
    cp_r buildpath/"node_modules", libexec if (buildpath/"node_modules").exist?
    (libexec/"packages").mkdir
    %w[config datetime dependency-manager server utils validation].each do |p|
      cp_r buildpath/"packages/#{p}", libexec/"packages/#{p}" if (buildpath/"packages/#{p}").exist?
    end

    (libexec/"bin/cli.mjs").write <<~EOS
      import { main } from '../dist/cli/index.js';
      main(process.argv);
    EOS

    (bin/"mc").write <<~EOS
      #!/bin/bash
      exec node "#{libexec}/bin/cli.mjs" "$@"
    EOS
    (bin/"deploy").write <<~EOS
      #!/bin/bash
      exec node "#{libexec}/bin/cli.mjs" "$@"
    EOS

    # Trigger script for post_install
    libexec.install buildpath/"scripts/deployment/trigger-deploy-after-brew.sh"
    chmod 0755, libexec/"trigger-deploy-after-brew.sh"

    # .env template for mc setup bootstrap
    (share/"maxwell-carmody").mkpath
    (share/"maxwell-carmody/env.example").write (buildpath/".env.example").read
  end

  def post_install
    deploy_dir = ENV["HOMEBREW_MC_DEPLOY_DIR"] || "#{Dir.home}/maxwell-carmody"
    repo_url = ENV["HOMEBREW_MC_REPO_URL"]
    repo_url = "#{homepage.chomp("/")}.git" if repo_url.to_s.empty? && homepage.to_s.include?("github")
    env_template_path = (share/"maxwell-carmody/env.example").to_s

    # Single path: mc setup. Bootstrap first (dirs, clone, config, .env template), then guided if TTY.
    system(
      { "DEPLOY_DIR" => deploy_dir, "REPO_URL" => repo_url.to_s, "ENV_TEMPLATE_PATH" => env_template_path, "MC_SETUP_BOOTSTRAP" => "1" },
      bin/"mc", "setup"
    )
    if ENV["HOMEBREW_MC_SKIP_SETUP"] != "1" && $stdin.tty?
      system bin/"mc", "setup"
    end

    system "sudo", bin/"mc", "agent", "install", "--daemon"

    if ENV["HOMEBREW_MC_TRIGGER_DEPLOY"] == "1"
      env = ENV["HOMEBREW_MC_DEPLOY_ENV"] || "staging"
      commit = ENV["HOMEBREW_MC_COMMIT"] || version.to_s
      system({ "DEPLOY_DIR" => deploy_dir }, libexec/"trigger-deploy-after-brew.sh", commit, env)
    end
  end

  def caveats
    <<~EOS
      Server setup (post_install) created ~/maxwell-carmody with directory structure,
      config.json, and .env.staging/.env.production from template.
      When run in a terminal, mc setup was run to configure certs and secrets interactively.
      Run mc setup anytime to replace keys or certs.
      Optional env vars: HOMEBREW_MC_REPO_URL, HOMEBREW_MC_DEPLOY_DIR,
      HOMEBREW_MC_SKIP_SETUP (skip guided mc setup),
      HOMEBREW_MC_TRIGGER_DEPLOY, HOMEBREW_MC_DEPLOY_ENV.
      To run the deploy agent at boot (server): post_install ran sudo mc agent install --daemon unless skipped.
      Verify with: mc agent status
      To fully uninstall: first run sudo mc agent uninstall --daemon, then brew uninstall maxwell-carmody.
    EOS
  end

  test do
    assert_match "Usage: mc <command>", shell_output("#{bin}/mc --help", 1)
  end
end
