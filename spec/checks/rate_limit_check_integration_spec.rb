# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/rate_limit_check"
require "rails_deploy_check/checks/rate_limit_check_integration"

RSpec.describe RailsDeployCheck::Checks::RateLimitCheckIntegration do
  subject(:integration) { described_class }

  def with_lockfile(content)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile.lock"), content)
      original = Dir.pwd
      Dir.chdir(dir) { yield }
    end
  end

  def with_env(vars)
    old = vars.transform_values { |_| ENV[_] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    vars.each_key { |k| old[k] ? ENV[k] = old[k] : ENV.delete(k) }
  end

  describe ".applicable?" do
    context "when rack-attack is in Gemfile.lock" do
      it "returns true" do
        with_lockfile("GEM\n  specs:\n    rack-attack (6.7.0)\n") do
          expect(integration.applicable?).to be true
        end
      end
    end

    context "when rack-throttle is in Gemfile.lock" do
      it "returns true" do
        with_lockfile("GEM\n  specs:\n    rack-throttle (0.7.0)\n") do
          expect(integration.applicable?).to be true
        end
      end
    end

    context "when in production environment without rate limiting gem" do
      it "returns true" do
        with_lockfile("GEM\n  specs:\n    rails (7.1.0)\n") do
          with_env("RAILS_ENV" => "production") do
            expect(integration.applicable?).to be true
          end
        end
      end
    end

    context "when in development without rate limiting gem" do
      it "returns false" do
        with_lockfile("GEM\n  specs:\n    rails (7.1.0)\n") do
          with_env("RAILS_ENV" => "development") do
            expect(integration.applicable?).to be false
          end
        end
      end
    end
  end

  describe ".build" do
    it "returns a RateLimitCheck instance" do
      expect(integration.build).to be_a(RailsDeployCheck::Checks::RateLimitCheck)
    end

    it "passes options through" do
      check = integration.build(app_path: "/tmp")
      expect(check).to be_a(RailsDeployCheck::Checks::RateLimitCheck)
    end
  end

  describe ".rack_attack_present?" do
    it "returns true when rack-attack is in lockfile" do
      with_lockfile("GEM\n  specs:\n    rack-attack (6.7.0)\n") do
        expect(integration.rack_attack_present?).to be true
      end
    end

    it "returns false when rack-attack is not in lockfile" do
      with_lockfile("GEM\n  specs:\n    rails (7.1.0)\n") do
        expect(integration.rack_attack_present?).to be false
      end
    end
  end
end
