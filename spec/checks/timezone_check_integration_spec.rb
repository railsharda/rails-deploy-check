# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/timezone_check"
require "rails_deploy_check/checks/timezone_check_integration"

RSpec.describe RailsDeployCheck::Checks::TimezoneCheckIntegration do
  subject(:integration) { described_class }

  def with_env(key, value)
    old = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = old
  end

  describe ".applicable?" do
    context "when config/application.rb exists" do
      it "returns true" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?)
          .with(File.join(Dir.pwd, "config", "application.rb"))
          .and_return(true)

        expect(integration.applicable?).to be true
      end
    end

    context "when TZ env variable is set" do
      it "returns true" do
        allow(File).to receive(:exist?).and_return(false)
        with_env("TZ", "America/New_York") do
          expect(integration.applicable?).to be true
        end
      end
    end

    context "when neither condition is met" do
      it "returns false" do
        allow(File).to receive(:exist?).and_return(false)
        with_env("TZ", nil) do
          expect(integration.applicable?).to be false
        end
      end
    end
  end

  describe ".build" do
    it "returns a TimezoneCheck instance" do
      check = integration.build(app_path: "/tmp/myapp")
      expect(check).to be_a(RailsDeployCheck::Checks::TimezoneCheck)
    end

    it "uses Dir.pwd as default app_path" do
      check = integration.build
      expect(check).to be_a(RailsDeployCheck::Checks::TimezoneCheck)
    end

    it "passes TZ env to the check" do
      with_env("TZ", "UTC") do
        check = integration.build(app_path: "/tmp/myapp")
        expect(check).to be_a(RailsDeployCheck::Checks::TimezoneCheck)
      end
    end
  end

  describe ".rails_app?" do
    it "returns true when config/application.rb exists" do
      allow(File).to receive(:exist?)
        .with(File.join(Dir.pwd, "config", "application.rb"))
        .and_return(true)
      expect(integration.rails_app?).to be true
    end

    it "returns false when config/application.rb is missing" do
      allow(File).to receive(:exist?)
        .with(File.join(Dir.pwd, "config", "application.rb"))
        .and_return(false)
      expect(integration.rails_app?).to be false
    end
  end

  describe ".tz_env_present?" do
    it "returns true when TZ is set" do
      with_env("TZ", "Europe/London") do
        expect(integration.tz_env_present?).to be true
      end
    end

    it "returns false when TZ is nil" do
      with_env("TZ", nil) do
        expect(integration.tz_env_present?).to be false
      end
    end

    it "returns false when TZ is empty string" do
      with_env("TZ", "") do
        expect(integration.tz_env_present?).to be false
      end
    end
  end
end
