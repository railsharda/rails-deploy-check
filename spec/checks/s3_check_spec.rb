# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/s3_check"

RSpec.describe RailsDeployCheck::Checks::S3Check do
  def build_check(options = {})
    described_class.new(options)
  end

  around do |example|
    original = ENV.to_h
    example.run
    ENV.replace(original)
  end

  def clear_s3_env
    %w[
      AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
      AWS_REGION AWS_DEFAULT_REGION
      AWS_S3_BUCKET S3_BUCKET
      AWS_S3_ENDPOINT S3_ENDPOINT
    ].each { |k| ENV.delete(k) }
  end

  before { clear_s3_env }

  describe "#run" do
    context "when all required env vars are set" do
      before do
        ENV["AWS_ACCESS_KEY_ID"] = "AKIAIOSFODNN7EXAMPLE"
        ENV["AWS_SECRET_ACCESS_KEY"] = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        ENV["AWS_REGION"] = "us-east-1"
        ENV["AWS_S3_BUCKET"] = "my-app-bucket"
      end

      it "returns a passing result" do
        result = build_check.run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
      end

      it "includes info messages for each setting" do
        result = build_check.run
        expect(result.infos.join).to include("AWS_ACCESS_KEY_ID")
        expect(result.infos.join).to include("us-east-1")
        expect(result.infos.join).to include("my-app-bucket")
      end
    end

    context "when access key is missing" do
      before do
        ENV["AWS_SECRET_ACCESS_KEY"] = "secret"
        ENV["AWS_REGION"] = "us-east-1"
      end

      it "adds an error" do
        result = build_check.run
        expect(result.errors).to include(match(/AWS_ACCESS_KEY_ID/))
      end
    end

    context "when secret key is missing" do
      before { ENV["AWS_ACCESS_KEY_ID"] = "key" }

      it "adds an error" do
        result = build_check.run
        expect(result.errors).to include(match(/AWS_SECRET_ACCESS_KEY/))
      end
    end

    context "when region is missing" do
      before do
        ENV["AWS_ACCESS_KEY_ID"] = "key"
        ENV["AWS_SECRET_ACCESS_KEY"] = "secret"
      end

      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(match(/AWS_REGION/))
      end
    end

    context "when bucket is not set" do
      before do
        ENV["AWS_ACCESS_KEY_ID"] = "key"
        ENV["AWS_SECRET_ACCESS_KEY"] = "secret"
        ENV["AWS_REGION"] = "eu-west-1"
      end

      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(match(/bucket/i))
      end
    end

    context "when a custom endpoint is provided" do
      before do
        ENV["AWS_ACCESS_KEY_ID"] = "key"
        ENV["AWS_SECRET_ACCESS_KEY"] = "secret"
        ENV["AWS_REGION"] = "us-east-1"
        ENV["AWS_S3_BUCKET"] = "bucket"
      end

      it "accepts a valid https endpoint" do
        ENV["AWS_S3_ENDPOINT"] = "https://s3.example.com"
        result = build_check.run
        expect(result.errors).to be_empty
        expect(result.infos.join).to include("https://s3.example.com")
      end

      it "rejects an endpoint with an invalid scheme" do
        ENV["AWS_S3_ENDPOINT"] = "ftp://s3.example.com"
        result = build_check.run
        expect(result.errors).to include(match(/http or https/))
      end

      it "rejects a completely invalid URI" do
        ENV["AWS_S3_ENDPOINT"] = "not a uri !!"
        result = build_check.run
        expect(result.errors).to include(match(/not a valid URI/))
      end
    end

    context "when options hash is used instead of env vars" do
      it "reads credentials from the options hash" do
        check = build_check(
          access_key_id: "OPTIONKEY",
          secret_access_key: "OPTIONSECRET",
          region: "ap-southeast-1",
          bucket: "option-bucket"
        )
        result = check.run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
      end
    end
  end
end
