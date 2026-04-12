# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/ssl_expiry_check"
require "rails_deploy_check/checks/ssl_expiry_check_integration"

RSpec.describe RailsDeployCheck::Checks::SslExpiryCheckIntegration do
  subject(:integration) { described_class }

  def with_env(vars, &block)
    old = vars.keys.each_with_object({}) { |k, h| h[k] = ENV[k.to_s] }
    vars.each { |k, v| ENV[k.to_s] = v }
    block.call
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v }
  end

  describe ".applicable?" do
    it "returns true when SSL_EXPIRY_HOST is set" do
      with_env("SSL_EXPIRY_HOST" => "example.com") do
        expect(integration.applicable?).to be true
      end
    end

    it "returns true when APP_HOST is set" do
      with_env("APP_HOST" => "example.com") do
        expect(integration.applicable?).to be true
      end
    end

    it "returns true in production environment" do
      with_env("RAILS_ENV" => "production", "SSL_EXPIRY_HOST" => nil, "APP_HOST" => nil) do
        expect(integration.applicable?).to be true
      end
    end

    it "returns false when no relevant env vars are set" do
      with_env("SSL_EXPIRY_HOST" => nil, "APP_HOST" => nil, "RAILS_ENV" => "test", "RACK_ENV" => "test") do
        expect(integration.applicable?).to be false
      end
    end
  end

  describe ".build" do
    it "returns nil when no host is configured" do
      with_env("SSL_EXPIRY_HOST" => nil, "APP_HOST" => nil) do
        expect(integration.build).to be_nil
      end
    end

    it "builds a check with SSL_EXPIRY_HOST" do
      with_env("SSL_EXPIRY_HOST" => "example.com") do
        check = integration.build
        expect(check).to be_a(RailsDeployCheck::Checks::SslExpiryCheck)
      end
    end

    it "builds a check with APP_HOST as fallback" do
      with_env("SSL_EXPIRY_HOST" => nil, "APP_HOST" => "fallback.com") do
        check = integration.build
        expect(check).to be_a(RailsDeployCheck::Checks::SslExpiryCheck)
      end
    end

    it "uses config host over environment variables" do
      with_env("APP_HOST" => "env.com") do
        check = integration.build(host: "config.com")
        expect(check).to be_a(RailsDeployCheck::Checks::SslExpiryCheck)
      end
    end
  end
end
