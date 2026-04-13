# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/env_vars_check"
require "rails_deploy_check/checks/env_vars_check_integration"

RSpec.describe RailsDeployCheck::Checks::EnvVarsCheckIntegration do
  subject(:integration) { described_class }

  describe ".applicable?" do
    context "when running in a Rails app directory" do
      it "returns true when config/application.rb exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/application.rb").and_return(true)
        expect(integration.applicable?).to be true
      end

      it "returns true when config/environment.rb exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/application.rb").and_return(false)
        allow(File).to receive(:exist?).with("config/environment.rb").and_return(true)
        expect(integration.applicable?).to be true
      end
    end

    context "when a .env file is present" do
      it "returns true" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/application.rb").and_return(false)
        allow(File).to receive(:exist?).with("config/environment.rb").and_return(false)
        allow(File).to receive(:exist?).with(".env").and_return(true)
        expect(integration.applicable?).to be true
      end
    end

    context "when RAILS_ENV is set" do
      around do |example|
        ENV["RAILS_ENV"] = "production"
        example.run
        ENV.delete("RAILS_ENV")
      end

      it "returns true" do
        allow(File).to receive(:exist?).and_return(false)
        expect(integration.applicable?).to be true
      end
    end
  end

  describe ".build" do
    it "returns an EnvVarsCheck instance" do
      check = integration.build(required_vars: [])
      expect(check).to be_a(RailsDeployCheck::Checks::EnvVarsCheck)
    end
  end

  describe ".register" do
    it "registers the check when applicable" do
      registry = {}
      def registry.register(key, check)
        self[key] = check
      end

      allow(integration).to receive(:applicable?).and_return(true)
      integration.register(registry)
      expect(registry).to have_key(:env_vars)
    end

    it "does not register when not applicable" do
      registry = {}
      def registry.register(key, check)
        self[key] = check
      end

      allow(integration).to receive(:applicable?).and_return(false)
      integration.register(registry)
      expect(registry).not_to have_key(:env_vars)
    end
  end
end
