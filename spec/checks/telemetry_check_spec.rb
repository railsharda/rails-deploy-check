# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/telemetry_check"

RSpec.describe RailsDeployCheck::Checks::TelemetryCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  around do |example|
    with_tmp_rails_app do |path|
      @app_path = path
      example.run
    end
  end

  describe "#run" do
    context "when no telemetry provider is configured" do
      it "adds a warning when warn_if_missing is true" do
        check = build_check(app_path: @app_path, warn_if_missing: true)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("No telemetry") }).to be true
      end

      it "does not warn when warn_if_missing is false" do
        check = build_check(app_path: @app_path, warn_if_missing: false)
        result = check.run
        expect(result.warnings.none? { |w| w.include?("No telemetry") }).to be true
      end
    end

    context "when a known provider env var is set" do
      around do |example|
        old = ENV["DATADOG_API_KEY"]
        ENV["DATADOG_API_KEY"] = "test-key-123"
        example.run
      ensure
        ENV["DATADOG_API_KEY"] = old
      end

      it "reports the detected provider" do
        check = build_check(app_path: @app_path)
        result = check.run
        expect(result.info.any? { |i| i.include?("DATADOG_API_KEY") }).to be true
      end

      it "passes without errors" do
        check = build_check(app_path: @app_path)
        result = check.run
        expect(result.errors).to be_empty
      end
    end

    context "when a required_provider is specified" do
      it "adds an error when the required key is missing" do
        check = build_check(app_path: @app_path, required_provider: "HONEYBADGER_API_KEY")
        result = check.run
        expect(result.errors.any? { |e| e.include?("HONEYBADGER_API_KEY") }).to be true
      end

      it "adds info when the required key is present" do
        old = ENV["HONEYBADGER_API_KEY"]
        ENV["HONEYBADGER_API_KEY"] = "hb-key-abc"
        check = build_check(app_path: @app_path, required_provider: "HONEYBADGER_API_KEY")
        result = check.run
        expect(result.errors).to be_empty
        expect(result.info.any? { |i| i.include?("HONEYBADGER_API_KEY") }).to be true
      ensure
        ENV["HONEYBADGER_API_KEY"] = old
      end
    end

    context "when a telemetry initializer exists" do
      before do
        create_file(File.join(@app_path, "config", "initializers", "datadog.rb"), "# Datadog config")
      end

      it "reports the initializer as info" do
        check = build_check(app_path: @app_path)
        result = check.run
        expect(result.info.any? { |i| i.include?("datadog.rb") }).to be true
      end
    end

    context "when no telemetry initializer exists" do
      it "adds a warning about missing initializer" do
        FileUtils.mkdir_p(File.join(@app_path, "config", "initializers"))
        check = build_check(app_path: @app_path)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("initializer") }).to be true
      end
    end
  end
end
