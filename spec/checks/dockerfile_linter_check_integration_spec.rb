# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/dockerfile_linter_check"
require "rails_deploy_check/checks/dockerfile_linter_check_integration"

RSpec.describe RailsDeployCheck::Checks::DockerfileLinterCheckIntegration do
  subject(:integration) { described_class }

  around do |example|
    Dir.mktmpdir do |dir|
      @original_dir = Dir.pwd
      Dir.chdir(dir)
      @tmpdir = dir
      example.run
      Dir.chdir(@original_dir)
    end
  end

  describe ".applicable?" do
    context "when Dockerfile is present" do
      it "returns true" do
        File.write(File.join(@tmpdir, "Dockerfile"), "FROM ruby:3.3.0-slim\n")
        expect(integration.applicable?).to be true
      end
    end

    context "when .dockerignore is present" do
      it "returns true" do
        File.write(File.join(@tmpdir, ".dockerignore"), "log/\ntmp/\n")
        expect(integration.applicable?).to be true
      end
    end

    context "when neither file is present" do
      it "returns false" do
        expect(integration.applicable?).to be false
      end
    end
  end

  describe ".build" do
    it "returns a DockerfileLinterCheck instance" do
      expect(integration.build).to be_a(RailsDeployCheck::Checks::DockerfileLinterCheck)
    end
  end

  describe ".register" do
    context "when applicable" do
      it "registers the check" do
        File.write(File.join(@tmpdir, "Dockerfile"), "FROM ruby:3.3.0-slim\n")
        registry = double("registry")
        expect(registry).to receive(:register).with(:dockerfile_linter, anything)
        integration.register(registry)
      end
    end

    context "when not applicable" do
      it "does not register the check" do
        registry = double("registry")
        expect(registry).not_to receive(:register)
        integration.register(registry)
      end
    end
  end
end
