# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/datadog_check"

RSpec.describe RailsDeployCheck::Checks::DatadogCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe "#run" do
    context "when DD_API_KEY is present and valid" do
      it "adds an info message for the API key" do
        check = build_check(api_key: "a" * 32)
        result = check.run
        expect(result.infos).to include(a_string_matching(/DD_API_KEY is present/))
      end
    end

    context "when DD_API_KEY is missing" do
      it "adds an error" do
        check = build_check(api_key: nil)
        result = check.run
        expect(result.errors).to include(a_string_matching(/DD_API_KEY environment variable is not set/))
      end
    end

    context "when DD_API_KEY is too short" do
      it "adds a warning" do
        check = build_check(api_key: "short")
        result = check.run
        expect(result.warnings).to include(a_string_matching(/appears too short/))
      end
    end

    context "when Gemfile.lock contains ddtrace" do
      it "adds an info message about the gem" do
        with_tmp_rails_app do |app_path|
          lockfile = File.join(app_path, "Gemfile.lock")
          create_file(lockfile, "GEM\n  specs:\n    ddtrace (1.20.0)\n")
          check = build_check(api_key: "a" * 32, app_path: app_path, lockfile_path: lockfile)
          result = check.run
          expect(result.infos).to include(a_string_matching(/Datadog gem found/))
        end
      end
    end

    context "when Gemfile.lock does not contain a Datadog gem" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          lockfile = File.join(app_path, "Gemfile.lock")
          create_file(lockfile, "GEM\n  specs:\n    rails (7.0.0)\n")
          check = build_check(api_key: "a" * 32, app_path: app_path, lockfile_path: lockfile)
          result = check.run
          expect(result.warnings).to include(a_string_matching(/No Datadog gem/))
        end
      end
    end

    context "when the Datadog initializer exists" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          initializer = File.join(app_path, "config", "initializers", "datadog.rb")
          create_file(initializer, "Datadog.configure { |c| }\n")
          check = build_check(api_key: "a" * 32, app_path: app_path)
          result = check.run
          expect(result.infos).to include(a_string_matching(/Datadog initializer found/))
        end
      end
    end

    context "when DD_SITE is a valid Datadog site" do
      it "adds an info message" do
        check = build_check(api_key: "a" * 32, site: "app.datadoghq.com")
        result = check.run
        expect(result.infos).to include(a_string_matching(/DD_SITE is set to app\.datadoghq\.com/))
      end
    end

    context "when DD_SITE is an unknown domain" do
      it "adds a warning" do
        check = build_check(api_key: "a" * 32, site: "app.example.com")
        result = check.run
        expect(result.warnings).to include(a_string_matching(/does not match a known Datadog site pattern/))
      end
    end
  end
end
