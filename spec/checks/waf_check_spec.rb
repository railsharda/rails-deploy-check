require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::WafCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe "#run" do
    context "when WAF_PROVIDER is not set" do
      it "adds a warning about missing WAF provider" do
        with_tmp_rails_app do |app_path|
          ClimateControl.modify("WAF_PROVIDER" => nil, "WAF_URL" => nil) do
            check = build_check(app_path: app_path)
            result = check.run
            expect(result.warnings.any? { |w| w.include?("No WAF provider") }).to be true
          end
        end
      end
    end

    context "when WAF_PROVIDER is set to a known provider" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          ClimateControl.modify("WAF_PROVIDER" => "cloudflare") do
            check = build_check(app_path: app_path)
            result = check.run
            expect(result.infos.any? { |i| i.include?("cloudflare") }).to be true
            expect(result.warnings.none? { |w| w.include?("Unknown WAF provider") }).to be true
          end
        end
      end
    end

    context "when WAF_PROVIDER is set to an unknown provider" do
      it "adds a warning about unknown provider" do
        with_tmp_rails_app do |app_path|
          ClimateControl.modify("WAF_PROVIDER" => "myrandomprovider") do
            check = build_check(app_path: app_path)
            result = check.run
            expect(result.warnings.any? { |w| w.include?("Unknown WAF provider") }).to be true
          end
        end
      end
    end

    context "when rack-attack is in Gemfile.lock" do
      it "adds an info message about the gem" do
        with_tmp_rails_app do |app_path|
          lockfile = File.join(app_path, "Gemfile.lock")
          create_file(lockfile, "GEM\n  specs:\n    rack-attack (6.6.1)\n")
          check = build_check(app_path: app_path)
          result = check.run
          expect(result.infos.any? { |i| i.include?("rack-attack") }).to be true
        end
      end
    end

    context "when no WAF gem is in Gemfile.lock" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          lockfile = File.join(app_path, "Gemfile.lock")
          create_file(lockfile, "GEM\n  specs:\n    rails (7.0.0)\n")
          check = build_check(app_path: app_path)
          result = check.run
          expect(result.warnings.any? { |w| w.include?("No WAF-related gem") }).to be true
        end
      end
    end

    context "when a WAF initializer exists" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          init_path = File.join(app_path, "config", "initializers", "rack_attack.rb")
          create_file(init_path, "# rack attack config")
          check = build_check(app_path: app_path)
          result = check.run
          expect(result.infos.any? { |i| i.include?("rack_attack.rb") }).to be true
        end
      end
    end

    context "when WAF_BLOCKED_IPS is set" do
      it "reports the number of blocked IPs" do
        with_tmp_rails_app do |app_path|
          ClimateControl.modify("WAF_BLOCKED_IPS" => "1.2.3.4,5.6.7.8,9.10.11.12") do
            check = build_check(app_path: app_path)
            result = check.run
            expect(result.infos.any? { |i| i.include?("3 entries") }).to be true
          end
        end
      end
    end
  end
end
