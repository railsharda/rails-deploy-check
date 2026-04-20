# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/prometheus_check"
require "rails_deploy_check/checks/prometheus_check_integration"

RSpec.describe RailsDeployCheck::Checks::PrometheusCheckIntegration do
  subject(:integration) { described_class }

  def with_env(vars, &block)
    old_values = vars.keys.each_with_object({}) { |k, h| h[k] = ENV[k] }
    vars.each { |k, v| ENV[k] = v }
    block.call
  ensure
    old_values.each { |k, v| v.nil? ? ENV.delete(k) : ENV.store(k, v) }
  end

  def clear_prometheus_env
    ENV.delete("PROMETHEUS_METRICS_URL")
    ENV.delete("PROMETHEUS_PUSHGATEWAY_URL")
  end

  before { clear_prometheus_env }
  after  { clear_prometheus_env }

  describe ".applicable?" do
    context "when PROMETHEUS_METRICS_URL is set" do
      it "returns true" do
        with_env("PROMETHEUS_METRICS_URL" => "http://localhost:9090/metrics") do
          expect(integration.applicable?).to be true
        end
      end
    end

    context "when PROMETHEUS_PUSHGATEWAY_URL is set" do
      it "returns true" do
        with_env("PROMETHEUS_PUSHGATEWAY_URL" => "http://localhost:9091") do
          expect(integration.applicable?).to be true
        end
      end
    end

    context "when no env vars are set and no lockfile present" do
      it "returns false" do
        allow(integration).to receive(:prometheus_gem_in_lockfile?).and_return(false)
        expect(integration.applicable?).to be false
      end
    end

    context "when prometheus-client is in Gemfile.lock" do
      it "returns true" do
        allow(integration).to receive(:prometheus_gem_in_lockfile?).and_return(true)
        expect(integration.applicable?).to be true
      end
    end
  end

  describe ".build" do
    it "returns a PrometheusCheck instance" do
      check = integration.build
      expect(check).to be_a(RailsDeployCheck::Checks::PrometheusCheck)
    end

    it "passes options to the check" do
      check = integration.build(metrics_url: "http://example.com/metrics")
      expect(check).to be_a(RailsDeployCheck::Checks::PrometheusCheck)
    end
  end

  describe ".register" do
    let(:registry) { double("registry") }

    context "when applicable" do
      it "registers the check" do
        allow(integration).to receive(:applicable?).and_return(true)
        expect(registry).to receive(:register).with(:prometheus, anything)
        integration.register(registry)
      end
    end

    context "when not applicable" do
      it "does not register the check" do
        allow(integration).to receive(:applicable?).and_return(false)
        expect(registry).not_to receive(:register)
        integration.register(registry)
      end
    end
  end
end
