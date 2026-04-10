# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/ci_check"

RSpec.describe RailsDeployCheck::Checks::CiCheck do
  def build_check(config = {})
    described_class.new(config)
  end

  def create_file(base_path, relative_path, content = "")
    full_path = File.join(base_path, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  around do |example|
    with_tmp_rails_app do |app_path|
      @app_path = app_path
      example.run
    end
  end

  describe "#run" do
    context "when a known CI env var is set" do
      it "adds an info message about detected CI" do
        with_env("GITHUB_ACTIONS" => "true") do
          result = build_check(app_path: @app_path).run
          expect(result.infos.any? { |i| i.include?("GITHUB_ACTIONS") }).to be true
        end
      end
    end

    context "when no CI env var is set and require_ci is false" do
      it "adds a warning" do
        with_clean_env do
          result = build_check(app_path: @app_path, require_ci: false).run
          expect(result.warnings.any? { |w| w.include?("No CI environment") }).to be true
        end
      end
    end

    context "when no CI env var is set and require_ci is true" do
      it "adds an error" do
        with_clean_env do
          result = build_check(app_path: @app_path, require_ci: true).run
          expect(result.errors.any? { |e| e.include?("No CI environment") }).to be true
        end
      end
    end

    context "when a CI config file exists" do
      it "adds an info message for .travis.yml" do
        create_file(@app_path, ".travis.yml", "language: ruby")
        with_clean_env do
          result = build_check(app_path: @app_path).run
          expect(result.infos.any? { |i| i.include?("travis") }).to be true
        end
      end

      it "adds an info message for .github/workflows directory" do
        create_file(@app_path, ".github/workflows/ci.yml", "name: CI")
        with_clean_env do
          result = build_check(app_path: @app_path).run
          expect(result.infos.any? { |i| i.include?("github_actions") }).to be true
        end
      end
    end

    context "when no CI config file exists" do
      it "adds a warning about missing CI config" do
        with_clean_env do
          result = build_check(app_path: @app_path).run
          expect(result.warnings.any? { |w| w.include?("No CI configuration file") }).to be true
        end
      end
    end
  end

  def with_env(vars, &block)
    old = vars.keys.map { |k| [k, ENV[k]] }.to_h
    vars.each { |k, v| ENV[k] = v }
    block.call
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  def with_clean_env(&block)
    ci_vars = RailsDeployCheck::Checks::CiCheck::CI_ENV_VARS
    saved = ci_vars.map { |k| [k, ENV[k]] }.to_h
    ci_vars.each { |k| ENV.delete(k) }
    block.call
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
