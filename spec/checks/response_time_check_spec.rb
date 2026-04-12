# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/response_time_check"

RSpec.describe RailsDeployCheck::Checks::ResponseTimeCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when no URL is configured" do
      it "adds a warning" do
        check = build_check(url: nil)
        allow(ENV).to receive(:[]).with("HEALTH_CHECK_URL").and_return(nil)
        allow(ENV).to receive(:[]).with("APP_URL").and_return(nil)
        result = check.run
        expect(result.warnings).not_to be_empty
        expect(result.warnings.first).to include("No URL configured")
      end
    end

    context "when the URL is invalid" do
      it "adds an error for a malformed URL" do
        check = build_check(url: "not a url")
        # stub measure_response_time to raise URI error path
        allow_any_instance_of(described_class).to receive(:measure_response_time).and_raise(URI::InvalidURIError)
        result = check.run
        expect(result.errors).not_to be_empty
      end
    end

    context "when the endpoint is unreachable" do
      it "adds an error" do
        check = build_check(url: "http://localhost:19999/")
        allow_any_instance_of(described_class).to receive(:measure_response_time).and_return(nil)
        result = check.run
        expect(result.errors.first).to include("Could not connect")
      end
    end

    context "when response time exceeds the error threshold" do
      it "adds an error" do
        check = build_check(url: "http://example.com", threshold_ms: 500, warning_ms: 200)
        allow_any_instance_of(described_class).to receive(:measure_response_time).and_return(600)
        result = check.run
        expect(result.errors.first).to include("exceeds threshold")
      end
    end

    context "when response time is between warning and error thresholds" do
      it "adds a warning" do
        check = build_check(url: "http://example.com", threshold_ms: 2000, warning_ms: 500)
        allow_any_instance_of(described_class).to receive(:measure_response_time).and_return(800)
        result = check.run
        expect(result.warnings.first).to include("above warning threshold")
      end
    end

    context "when response time is within acceptable range" do
      it "adds an info message" do
        check = build_check(url: "http://example.com", threshold_ms: 2000, warning_ms: 1000)
        allow_any_instance_of(described_class).to receive(:measure_response_time).and_return(300)
        result = check.run
        expect(result.infos.any? { |i| i.include?("within acceptable range") }).to be true
      end
    end
  end
end
