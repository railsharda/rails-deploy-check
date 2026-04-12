# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/sentry_check"

RSpec.describe RailsDeployCheck::Checks::SentryCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  around do |example|
    with_tmp_rails_app do |app_path|
      @app_path = app_path
      example.run
    end
  end

  describe "#run" do
    context "when SENTRY_DSN is not set" do
      it "adds a warning about missing DSN" do
        check = build_check(app_path: @app_path, sentry_dsn: nil)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("SENTRY_DSN") }).to be true
      end
    end

    context "when SENTRY_DSN is set to a valid sentry.io URL" do
      it "adds an info message confirming DSN is configured" do
        check = build_check(app_path: @app_path, sentry_dsn: "https://abc123@o0.ingest.sentry.io/456")
        result = check.run
        expect(result.infos.any? { |i| i.include?("SENTRY_DSN is configured") }).to be true
        expect(result.errors).to be_empty
      end
    end

    context "when SENTRY_DSN has an invalid format" do
      it "adds an error about invalid URI" do
        check = build_check(app_path: @app_path, sentry_dsn: "not-a-valid-dsn")
        result = check.run
        expect(result.errors.any? { |e| e.include?("valid") }).to be true
      end
    end

    context "when SENTRY_DSN points to an unknown host" do
      it "adds a warning about unrecognised host" do
        check = build_check(app_path: @app_path, sentry_dsn: "https://key@custom.internal.host/1")
        result = check.run
        expect(result.warnings.any? { |w| w.include?("recognised Sentry ingest host") }).to be true
      end
    end

    context "when Gemfile.lock contains sentry-ruby" do
      it "adds an info message about the gem" do
        create_file(File.join(@app_path, "Gemfile.lock"), "    sentry-ruby (5.6.0)\n    sentry-rails (5.6.0)\n")
        check = build_check(app_path: @app_path, sentry_dsn: nil)
        result = check.run
        expect(result.infos.any? { |i| i.include?("Sentry gem detected") }).to be true
      end
    end

    context "when Gemfile.lock does not contain sentry gems" do
      it "adds a warning about missing gem" do
        create_file(File.join(@app_path, "Gemfile.lock"), "    rails (7.0.0)\n")
        check = build_check(app_path: @app_path, sentry_dsn: nil)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("sentry-ruby") }).to be true
      end
    end

    context "when sentry initializer exists" do
      it "adds an info message" do
        create_file(File.join(@app_path, "config", "initializers", "sentry.rb"), "Sentry.init {}\n")
        check = build_check(app_path: @app_path, sentry_dsn: nil)
        result = check.run
        expect(result.infos.any? { |i| i.include?("Sentry initializer found") }).to be true
      end
    end

    context "when sentry initializer is missing" do
      it "adds a warning" do
        check = build_check(app_path: @app_path, sentry_dsn: nil)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("No Sentry initializer") }).to be true
      end
    end
  end
end
