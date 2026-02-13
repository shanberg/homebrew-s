# typed: false
# frozen_string_literal: true

class MaxwellCarmody < Formula
  desc "Multi-application architecture for self-hosted services (mc/deploy, gateway, db, validate CLIs)"
  homepage "https://github.com/shanberg/home-services"
  head "git@github.com:shanberg/home-services.git", branch: "main", using: :git

  depends_on "node" => :build
  depends_on "pnpm" => :build

  def install
    system "cp", "-R", "#{buildpath}/.", libexec
    system "pnpm", "install", :dir => libexec
    # Build deployment CLI and its workspace deps so mc/deploy resolve @mc/* dist/
    system "pnpm", "exec", "turbo", "run", "build", "--filter=@mc/deployment...", :dir => libexec
    tsx = libexec/"node_modules/.bin/tsx"
    deploy_js = libexec/"packages/deployment/bin/deploy.js"
    (bin/"mc").write <<~EOS
      #!/bin/sh
      exec "#{tsx}" "#{deploy_js}" "$@"
    EOS
    (bin/"deploy").write <<~EOS
      #!/bin/sh
      exec "#{tsx}" "#{deploy_js}" "$@"
    EOS
    (bin/"gateway").write <<~EOS
      #!/bin/sh
      exec pnpm -C "#{libexec}" run gateway "$@"
    EOS
    (bin/"db").write <<~EOS
      #!/bin/sh
      exec pnpm -C "#{libexec}" run db "$@"
    EOS
    (bin/"validate").write <<~EOS
      #!/bin/sh
      exec pnpm -C "#{libexec}" exec validate "$@"
    EOS
    [bin/"mc", bin/"deploy", bin/"gateway", bin/"db", bin/"validate"].each { |f| chmod 0755, f }
    trigger_script = libexec/"scripts/deployment/trigger-deploy-after-brew.sh"
    chmod 0755, trigger_script if trigger_script.exist?
  end

  def post_install
    return unless ENV["HOMEBREW_MC_TRIGGER_DEPLOY"] == "1"

    commit = begin
      Utils.popen_read("git", "-C", libexec, "rev-parse", "HEAD").strip
    rescue StandardError
      ""
    end
    if commit.nil? || commit.empty?
      opoo "Could not determine install commit; run 'mc deploy staging' manually if needed."
      return
    end
    script = libexec/"scripts/deployment/trigger-deploy-after-brew.sh"
    unless script.exist?
      opoo "Trigger script not found at #{script}; run 'mc deploy staging' manually if needed."
      return
    end
    env = ENV["HOMEBREW_MC_DEPLOY_ENV"] || "staging"
    unless system(script, commit, env)
      opoo "Deploy trigger exited non-zero; check agent and config. Run 'mc deploy #{env}' manually if needed."
    end
  end

  test do
    mc_out = shell_output("#{bin}/mc --help 2>&1")
    assert_match(/Usage:.*(mc|deploy).*command/, mc_out, "mc --help should print usage")
    deploy_out = shell_output("#{bin}/deploy --help 2>&1")
    assert_match(/Usage:.*(mc|deploy).*command/, deploy_out, "deploy --help should print usage")
    assert_match(/Usage: gateway/, shell_output("#{bin}/gateway 2>&1"))
    assert_match(/Usage: db/, shell_output("#{bin}/db 2>&1"))
    assert_match(/validate/, shell_output("#{bin}/validate --help 2>&1"))
  end
end
