# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/nginx_check"
require "rails_deploy_check/checks/nginx_check_integration"

RSpec.describe RailsDeployCheck::Checks::NginxCheck do
  def build_check(options = {})
    described_class.new(**options)
  end

  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe "#run" do
    context "when nginx is not installed and no config exists" do
      it "adds a warning about nginx not being found" do
        allow_any_instance_of(described_class).to receive(:`)  # rubocop:disable RSpec/AnyInstance
          .with("which nginx 2>/dev/null").and_return("")
        allow_any_instance_of(described_class).to receive(:`)
          .with("pgrep -x nginx 2>/dev/null").and_return("")

        check = build_check(config_paths: ["/nonexistent/path/nginx.conf"], check_running: false)
        result = check.run

        expect(result.warnings.any? { |w| w.include?("nginx binary not found") }).to be true
      end
    end

    context "when an app-level nginx config exists" do
      it "reports the app config as info" do
        with_tmp_rails_app do |app_root|
          create_file(File.join(app_root, "config", "nginx.conf"), "worker_processes 2;")

          check = build_check(
            config_paths: [],
            check_running: false,
            app_root: app_root
          )

          allow(check).to receive(:`) .with("which nginx 2>/dev/null").and_return("")

          result = check.run
          expect(result.infos.any? { |i| i.include?("nginx.conf") }).to be true
        end
      end
    end

    context "when no app-level nginx config exists" do
      it "reports optional config as info" do
        with_tmp_rails_app do |app_root|
          check = build_check(
            config_paths: [],
            check_running: false,
            app_root: app_root
          )

          allow(check).to receive(:`).with("which nginx 2>/dev/null").and_return("")

          result = check.run
          expect(result.infos.any? { |i| i.include?("optional") }).to be true
        end
      end
    end

    context "when check_running is true and nginx is not running" do
      it "adds a warning that nginx is not running" do
        check = build_check(config_paths: [], check_running: true, app_root: Dir.pwd)

        allow(check).to receive(:`).with("which nginx 2>/dev/null").and_return("")
        allow(check).to receive(:`).with("pgrep -x nginx 2>/dev/null").and_return("")

        result = check.run
        expect(result.warnings.any? { |w| w.include?("nginx process does not appear") }).to be true
      end
    end
  end

  describe RailsDeployCheck::Checks::NginxCheckIntegration do
    describe ".build" do
      it "returns an NginxCheck instance" do
        check = described_class.build
        expect(check).to be_a(RailsDeployCheck::Checks::NginxCheck)
      end

      it "passes options through" do
        check = described_class.build(check_running: false)
        expect(check.instance_variable_get(:@check_running)).to be false
      end
    end

    describe ".applicable?" do
      it "returns false when nginx is absent and no config present" do
        allow(described_class).to receive(:nginx_installed?).and_return(false)
        allow(described_class).to receive(:nginx_config_present?).and_return(false)
        expect(described_class.applicable?).to be false
      end

      it "returns true when nginx is installed" do
        allow(described_class).to receive(:nginx_installed?).and_return(true)
        expect(described_class.applicable?).to be true
      end
    end
  end
end
