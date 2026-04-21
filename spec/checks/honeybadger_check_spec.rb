# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/honeybadger_check"

RSpec.describe RailsDeployCheck::Checks::HoneybadgerCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  around do |example|
    with_tmp_rails_app { example.run }
  end

  describe "#run" do
    context "when HONEYBADGER_API_KEY is set and gem is present" do
      it "returns no errors" do
        create_file("Gemfile.lock", "    honeybadger (5.1.0)\n")
        create_file("config/initializers/honeybadger.rb", "Honeybadger.configure { }")
        check = build_check(api_key: "abc123def456", app_path: Dir.pwd)
        result = check.run
        expect(result.errors).to be_empty
      end
    end

    context "when HONEYBADGER_API_KEY is missing" do
      it "adds an error" do
        check = build_check(api_key: nil, app_path: Dir.pwd)
        result = check.run
        expect(result.errors).to include(a_string_matching(/HONEYBADGER_API_KEY/))
      end
    end

    context "when API key has unexpected format" do
      it "adds a warning" do
        check = build_check(api_key: "not-a-hex-key!!", app_path: Dir.pwd)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/format looks unexpected/))
      end
    end

    context "when Gemfile.lock is missing" do
      it "adds a warning about lockfile" do
        check = build_check(api_key: "abc123", app_path: Dir.pwd)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/Gemfile.lock not found/))
      end
    end

    context "when honeybadger gem is not in Gemfile.lock" do
      it "adds a warning" do
        create_file("Gemfile.lock", "    rails (7.1.0)\n")
        check = build_check(api_key: "abc123", app_path: Dir.pwd)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/honeybadger gem not found/))
      end
    end

    context "when initializer is missing" do
      it "adds a warning" do
        create_file("Gemfile.lock", "    honeybadger (5.1.0)\n")
        check = build_check(api_key: "abc123", app_path: Dir.pwd)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/initializer not found/))
      end
    end

    context "when everything is configured correctly" do
      it "adds info messages" do
        create_file("Gemfile.lock", "    honeybadger (5.1.0)\n")
        create_file("config/initializers/honeybadger.rb", "Honeybadger.configure { }")
        check = build_check(api_key: "abc123def456", app_path: Dir.pwd)
        result = check.run
        expect(result.infos).to include(a_string_matching(/API key is configured/))
        expect(result.infos).to include(a_string_matching(/gem is present/))
        expect(result.infos).to include(a_string_matching(/initializer found/))
      end
    end
  end
end
