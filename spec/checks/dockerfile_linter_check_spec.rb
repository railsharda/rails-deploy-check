# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/dockerfile_linter_check"

RSpec.describe RailsDeployCheck::Checks::DockerfileLinterCheck do
  def build_check(options = {})
    described_class.new({ app_path: @tmpdir }.merge(options))
  end

  def create_file(name, content)
    path = File.join(@tmpdir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  context "when Dockerfile does not exist" do
    it "returns an info result" do
      result = build_check.run
      expect(result.infos).not_to be_empty
      expect(result.errors).to be_empty
      expect(result.warnings).to be_empty
    end
  end

  context "when Dockerfile uses latest tag" do
    it "adds a warning" do
      create_file("Dockerfile", "FROM ruby:latest\nRUN echo hello\nHEALTHCHECK CMD curl -f http://localhost\nUSER app\n")
      result = build_check.run
      expect(result.warnings.any? { |w| w.include?("latest") }).to be true
    end
  end

  context "when Dockerfile is missing HEALTHCHECK" do
    it "adds a warning" do
      create_file("Dockerfile", "FROM ruby:3.3.0-slim\nUSER app\n")
      result = build_check.run
      expect(result.warnings.any? { |w| w.include?("HEALTHCHECK") }).to be true
    end
  end

  context "when Dockerfile is missing USER" do
    it "adds a warning" do
      create_file("Dockerfile", "FROM ruby:3.3.0-slim\nHEALTHCHECK CMD curl -f http://localhost\n")
      result = build_check.run
      expect(result.warnings.any? { |w| w.include?("USER") }).to be true
    end
  end

  context "when Dockerfile contains hardcoded secret in ENV" do
    it "adds an error" do
      create_file("Dockerfile", "FROM ruby:3.3.0-slim\nENV SECRET_KEY_BASE=abc123\nHEALTHCHECK CMD true\nUSER app\n")
      result = build_check.run
      expect(result.errors.any? { |e| e.include?("hardcoded secrets") }).to be true
    end
  end

  context "when Dockerfile sets USER root" do
    it "adds a warning" do
      create_file("Dockerfile", "FROM ruby:3.3.0-slim\nHEALTHCHECK CMD true\nUSER root\n")
      result = build_check.run
      expect(result.warnings.any? { |w| w.include?("root") }).to be true
    end
  end

  context "when Dockerfile is well-formed" do
    it "returns no errors or warnings" do
      create_file("Dockerfile", "FROM ruby:3.3.0-slim\nHEALTHCHECK CMD curl -f http://localhost || exit 1\nUSER app\n")
      result = build_check.run
      expect(result.errors).to be_empty
      expect(result.warnings).to be_empty
    end
  end
end
