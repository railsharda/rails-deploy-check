# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/env_vars_check"

RSpec.describe RailsDeployCheck::Checks::EnvVarsCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe "#run" do
    context "when required vars are present" do
      it "adds an info message" do
        check = build_check(required_vars: ["HOME"])
        result = check.run
        expect(result.infos).to include(a_string_matching(/required environment variables are present/i))
      end
    end

    context "when required vars are missing" do
      it "adds an error for each missing var" do
        check = build_check(required_vars: ["TOTALLY_MISSING_VAR_XYZ"])
        result = check.run
        expect(result.errors).to include(a_string_matching(/TOTALLY_MISSING_VAR_XYZ/))
      end
    end

    context "when env vars have placeholder values" do
      around do |example|
        ENV["MY_SECRET_KEY"] = "changeme"
        example.run
        ENV.delete("MY_SECRET_KEY")
      end

      it "adds a warning for placeholder values" do
        check = build_check(required_vars: [], warn_on_defaults: true)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/MY_SECRET_KEY.*placeholder/i))
      end

      it "does not warn when warn_on_defaults is false" do
        check = build_check(required_vars: [], warn_on_defaults: false)
        result = check.run
        expect(result.warnings).not_to include(a_string_matching(/MY_SECRET_KEY/))
      end
    end

    context "when .env file exists" do
      around do |example|
        Dir.mktmpdir do |dir|
          @tmp_dir = dir
          example.run
        end
      end

      it "warns about sensitive keys in .env file" do
        env_path = File.join(@tmp_dir, ".env")
        create_file(env_path, "DATABASE_PASSWORD=supersecret\nAPP_NAME=myapp\n")
        check = build_check(app_path: @tmp_dir, required_vars: [])
        result = check.run
        expect(result.warnings).to include(a_string_matching(/DATABASE_PASSWORD/i))
      end

      it "adds info when .env has no sensitive keys" do
        env_path = File.join(@tmp_dir, ".env")
        create_file(env_path, "APP_NAME=myapp\nRAILS_ENV=production\n")
        check = build_check(app_path: @tmp_dir, required_vars: [])
        result = check.run
        expect(result.infos).to include(a_string_matching(/.env file exists/i))
      end

      it "skips comment lines in .env" do
        env_path = File.join(@tmp_dir, ".env")
        create_file(env_path, "# DATABASE_PASSWORD is set elsewhere\nAPP_NAME=myapp\n")
        check = build_check(app_path: @tmp_dir, required_vars: [])
        result = check.run
        expect(result.warnings).to be_empty
      end
    end
  end
end
