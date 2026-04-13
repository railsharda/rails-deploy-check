# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/cloudwatch_check"
require "rails_deploy_check/checks/cloudwatch_check_integration"

RSpec.describe RailsDeployCheck::Checks::CloudwatchCheckIntegration do
  subject(:integration) { described_class }

  def with_env(vars, &block)
    old_values = vars.keys.each_with_object({}) { |k, h| h[k] = ENV[k.to_s] }
    vars.each { |k, v| ENV[k.to_s] = v }
    block.call
  ensure
    old_values.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v }
  end

  def clear_cloudwatch_env
    %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_DEFAULT_REGION CLOUDWATCH_LOG_GROUP].each do |key|
      ENV.delete(key)
    end
  end

  around do |example|
    clear_cloudwatch_env
    example.run
    clear_cloudwatch_env
  end

  describe ".applicable?" do
    context "when AWS_ACCESS_KEY_ID is set" do
      it "returns true" do
        with_env("AWS_ACCESS_KEY_ID" => "AKIAIOSFODNN7EXAMPLE") do
          expect(integration.applicable?).to be true
        end
      end
    end

    context "when CLOUDWATCH_LOG_GROUP is set" do
      it "returns true" do
        with_env("CLOUDWATCH_LOG_GROUP" => "/rails/production") do
          expect(integration.applicable?).to be true
        end
      end
    end

    context "when no AWS env vars or lockfile gems are present" do
      it "returns false" do
        allow(File).to receive(:exist?).and_return(false)
        expect(integration.applicable?).to be false
      end
    end
  end

  describe ".aws_sdk_in_lockfile?" do
    around do |example|
      Dir.mktmpdir do |dir|
        @orig_dir = Dir.pwd
        Dir.chdir(dir)
        example.run
        Dir.chdir(@orig_dir)
      end
    end

    it "returns true when aws-sdk-cloudwatchlogs is in Gemfile.lock" do
      File.write("Gemfile.lock", "    aws-sdk-cloudwatchlogs (1.2.3)\n")
      expect(integration.aws_sdk_in_lockfile?).to be true
    end

    it "returns false when aws-sdk is not in Gemfile.lock" do
      File.write("Gemfile.lock", "    rails (7.0.0)\n")
      expect(integration.aws_sdk_in_lockfile?).to be false
    end

    it "returns false when Gemfile.lock does not exist" do
      expect(integration.aws_sdk_in_lockfile?).to be false
    end
  end

  describe ".build" do
    it "returns a CloudwatchCheck instance" do
      expect(integration.build).to be_a(RailsDeployCheck::Checks::CloudwatchCheck)
    end
  end
end
