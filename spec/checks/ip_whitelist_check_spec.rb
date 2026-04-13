# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/ip_whitelist_check"

RSpec.describe RailsDeployCheck::Checks::IpWhitelistCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(root, relative_path, content = "")
    full_path = File.join(root, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "#run" do
    context "when IP_WHITELIST env var is set with valid IPs" do
      it "adds info messages for valid configuration" do
        result = build_check(env: { "IP_WHITELIST" => "192.168.1.1,10.0.0.0/8" }).run

        expect(result.infos).to include(match(/IP whitelist configured via IP_WHITELIST/))
        expect(result.infos).to include(match(/2 valid IP\/CIDR entries/))
        expect(result.errors).to be_empty
      end
    end

    context "when ALLOWED_IPS env var is set" do
      it "detects the alternate env var" do
        result = build_check(env: { "ALLOWED_IPS" => "172.16.0.1" }).run

        expect(result.infos).to include(match(/IP whitelist configured via ALLOWED_IPS/))
        expect(result.errors).to be_empty
      end
    end

    context "when no whitelist env var is set" do
      it "adds a warning" do
        result = build_check(env: {}).run

        expect(result.warnings).to include(match(/No IP whitelist environment variable found/))
        expect(result.errors).to be_empty
      end
    end

    context "when whitelist env var is set but empty" do
      it "adds a warning about empty value" do
        result = build_check(env: { "IP_WHITELIST" => "   " }).run

        expect(result.warnings).to include(match(/No IP whitelist environment variable found/))
      end
    end

    context "when whitelist contains invalid entries" do
      it "adds a warning about invalid entries" do
        result = build_check(env: { "IP_WHITELIST" => "192.168.1.1,not-an-ip,10.0.0.1" }).run

        expect(result.warnings).to include(match(/potentially invalid entries/))
        expect(result.warnings.first).to include("not-an-ip")
      end
    end

    context "when an initializer file exists" do
      it "reports the initializer as found" do
        with_tmp_rails_app do |root|
          create_file(root, "config/initializers/ip_whitelist.rb", "# whitelist config")

          result = build_check(root: root, env: { "IP_WHITELIST" => "127.0.0.1" }).run

          expect(result.infos).to include(match(/ip_whitelist.rb/))
        end
      end
    end

    context "when no initializer file exists" do
      it "reports initializer as optional" do
        with_tmp_rails_app do |root|
          result = build_check(root: root, env: { "IP_WHITELIST" => "127.0.0.1" }).run

          expect(result.infos).to include(match(/No IP whitelist initializer found \(optional\)/))
        end
      end
    end

    context "with localhost entry" do
      it "considers localhost valid" do
        result = build_check(env: { "IP_WHITELIST" => "localhost,127.0.0.1" }).run

        expect(result.warnings.any? { |w| w.include?("invalid") }).to be false
      end
    end
  end
end
