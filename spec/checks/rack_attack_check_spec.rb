# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/rack_attack_check"

RSpec.describe RailsDeployCheck::Checks::RackAttackCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(app_path:, env: {})
    described_class.new(app_path: app_path, env: env)
  end

  around do |example|
    with_tmp_rails_app { |path| @app_path = path; example.run }
  end

  describe "#run" do
    context "when rack-attack is not in Gemfile.lock" do
      it "adds a warning" do
        create_file(File.join(@app_path, "Gemfile.lock"), "GEM\n  specs:\n    rails (7.0.0)\n")
        result = build_check(app_path: @app_path).run
        expect(result.warnings).to include(match(/rack-attack gem not found/))
      end

      it "does not check initializer or cache store" do
        create_file(File.join(@app_path, "Gemfile.lock"), "GEM\n  specs:\n    rails (7.0.0)\n")
        result = build_check(app_path: @app_path).run
        expect(result.infos.join).not_to include("initializer")
        expect(result.warnings.join).not_to include("cache store")
      end
    end

    context "when rack-attack is in Gemfile.lock" do
      before do
        create_file(File.join(@app_path, "Gemfile.lock"), "GEM\n  specs:\n    rack-attack (6.7.0)\n")
      end

      it "adds an info message about the gem" do
        result = build_check(app_path: @app_path).run
        expect(result.infos).to include(match(/rack-attack gem found/))
      end

      context "when initializer is missing" do
        it "adds a warning about missing initializer" do
          result = build_check(app_path: @app_path).run
          expect(result.warnings).to include(match(/no initializer found/))
        end
      end

      context "when initializer exists" do
        before do
          create_file(
            File.join(@app_path, "config", "initializers", "rack_attack.rb"),
            "Rack::Attack.throttle('req/ip', limit: 300, period: 5.minutes) { |req| req.ip }\n"
          )
        end

        it "adds an info message about the initializer" do
          result = build_check(app_path: @app_path).run
          expect(result.infos).to include(match(/initializer found/))
        end

        it "warns when no cache store env variable is set" do
          result = build_check(app_path: @app_path, env: {}).run
          expect(result.warnings).to include(match(/No cache store URL found/))
        end

        it "adds info when REDIS_URL is configured" do
          result = build_check(app_path: @app_path, env: { "REDIS_URL" => "redis://localhost:6379" }).run
          expect(result.infos).to include(match(/Cache store environment variable configured/))
        end

        it "adds info when RACK_ATTACK_CACHE_URL is configured" do
          result = build_check(app_path: @app_path, env: { "RACK_ATTACK_CACHE_URL" => "redis://localhost:6379/1" }).run
          expect(result.infos).to include(match(/Cache store environment variable configured/))
        end

        it "adds info when throttle env variables are present" do
          env = { "REDIS_URL" => "redis://localhost:6379", "RACK_ATTACK_THROTTLE_LIMIT" => "100", "RACK_ATTACK_THROTTLE_PERIOD" => "60" }
          result = build_check(app_path: @app_path, env: env).run
          expect(result.infos).to include(match(/throttle env variables configured/))
        end

        it "adds info when throttle env variables are absent" do
          env = { "REDIS_URL" => "redis://localhost:6379" }
          result = build_check(app_path: @app_path, env: env).run
          expect(result.infos).to include(match(/not set via environment variables/))
        end
      end
    end
  end
end
