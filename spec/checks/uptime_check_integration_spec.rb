# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/uptime_check"
require "rails_deploy_check/checks/uptime_check_integration"

RSpec.describe RailsDeployCheck::Checks::UptimeCheckIntegration do
  subject(:integration) { described_class }

  let(:uptime_env_vars) do
    %w[UPTIME_URL APP_URL HEALTHCHECK_URL RENDER_EXTERNAL_URL HEROKU_APP_DEFAULT_DOMAIN_NAME]
  end

  def with_env(vars, &block)
    old = vars.keys.each_with_object({}) { |k, h| h[k] = ENV[k.to_s] }
    vars.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v }
    block.call
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v }
  end

  def clear_uptime_env(&block)
    cleared = uptime_env_vars.each_with_object({}) { |k, h| h[k] = nil }
    with_env(cleared, &block)
  end

  describe ".applicable?" do
    it "returns true when UPTIME_URL is set" do
      with_env("UPTIME_URL" => "https://example.com") do
        expect(integration.applicable?).to be true
      end
    end

    it "returns true when APP_URL is set" do
      clear_uptime_env do
        with_env("APP_URL" => "https://app.example.com") do
          expect(integration.applicable?).to be true
        end
      end
    end

    it "returns false when no uptime env vars are set" do
      clear_uptime_env do
        expect(integration.applicable?).to be false
      end
    end
  end

  describe ".detect_url" do
    it "prefers UPTIME_URL over APP_URL" do
      with_env("UPTIME_URL" => "https://uptime.com", "APP_URL" => "https://app.com") do
        expect(integration.detect_url).to eq("https://uptime.com")
      end
    end

    it "falls back to APP_URL when UPTIME_URL is absent" do
      clear_uptime_env do
        with_env("APP_URL" => "https://app.com") do
          expect(integration.detect_url).to eq("https://app.com")
        end
      end
    end

    it "returns nil when no vars are set" do
      clear_uptime_env do
        expect(integration.detect_url).to be_nil
      end
    end
  end

  describe ".build" do
    it "returns nil when no URL is detectable" do
      clear_uptime_env do
        expect(integration.build).to be_nil
      end
    end

    it "builds a check from UPTIME_URL" do
      with_env("UPTIME_URL" => "https://example.com") do
        check = integration.build
        expect(check).to be_a(RailsDeployCheck::Checks::UptimeCheck)
      end
    end

    it "prepends https:// when scheme is missing" do
      with_env("UPTIME_URL" => "example.com") do
        check = integration.build
        expect(check).to be_a(RailsDeployCheck::Checks::UptimeCheck)
      end
    end

    it "accepts explicit config url" do
      clear_uptime_env do
        check = integration.build(url: "https://config.com")
        expect(check).to be_a(RailsDeployCheck::Checks::UptimeCheck)
      end
    end
  end
end
