# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/cloudwatch_check"

RSpec.describe RailsDeployCheck::Checks::CloudwatchCheck do
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
    context "when all CloudWatch settings are configured" do
      it "returns info messages for each configured setting" do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "    aws-sdk-cloudwatchlogs (1.0.0)\n"
        )
        check = build_check(
          app_path: @app_path,
          region: "us-east-1",
          access_key_id: "AKIAIOSFODNN7EXAMPLE",
          secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
          log_group: "/rails/production"
        )
        result = check.run
        expect(result.infos).to include(a_string_matching(/us-east-1/))
        expect(result.infos).to include(a_string_matching(/log group/i))
        expect(result.errors).to be_empty
      end
    end

    context "when AWS region is missing" do
      it "adds an error" do
        check = build_check(
          app_path: @app_path,
          region: nil,
          access_key_id: "KEY",
          secret_access_key: "SECRET"
        )
        result = check.run
        expect(result.errors).to include(a_string_matching(/region/i))
      end
    end

    context "when AWS credentials are missing" do
      it "adds warnings for missing credentials" do
        check = build_check(
          app_path: @app_path,
          region: "eu-west-1",
          access_key_id: nil,
          secret_access_key: nil
        )
        result = check.run
        expect(result.warnings).to include(a_string_matching(/AWS_ACCESS_KEY_ID/i))
        expect(result.warnings).to include(a_string_matching(/AWS_SECRET_ACCESS_KEY/i))
      end
    end

    context "when log group is not configured" do
      it "adds a warning" do
        check = build_check(
          app_path: @app_path,
          region: "us-west-2",
          access_key_id: "KEY",
          secret_access_key: "SECRET",
          log_group: nil
        )
        result = check.run
        expect(result.warnings).to include(a_string_matching(/CLOUDWATCH_LOG_GROUP/i))
      end
    end

    context "when aws-sdk gem is not in Gemfile.lock" do
      it "adds a warning about missing SDK" do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "    rails (7.0.0)\n"
        )
        check = build_check(
          app_path: @app_path,
          region: "us-east-1",
          access_key_id: "KEY",
          secret_access_key: "SECRET",
          log_group: "/rails/app"
        )
        result = check.run
        expect(result.warnings).to include(a_string_matching(/aws-sdk-cloudwatchlogs/i))
      end
    end

    context "when Gemfile.lock does not exist" do
      it "adds a warning about missing lockfile" do
        check = build_check(
          app_path: @app_path,
          region: "us-east-1",
          access_key_id: "KEY",
          secret_access_key: "SECRET"
        )
        result = check.run
        expect(result.warnings).to include(a_string_matching(/Gemfile.lock/i))
      end
    end
  end
end
