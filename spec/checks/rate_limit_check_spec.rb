# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/rate_limit_check"

RSpec.describe RailsDeployCheck::Checks::RateLimitCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new({ app_path: @app_path }.merge(options))
  end

  around do |example|
    with_tmp_rails_app do |path|
      @app_path = path
      example.run
    end
  end

  describe "#run" do
    context "when rack-attack is in Gemfile.lock" do
      before do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "GEM\n  specs:\n    rack-attack (6.7.0)\n"
        )
      end

      it "reports rack-attack as detected" do
        result = build_check.run
        expect(result.infos.join).to include("rack-attack")
      end

      context "with an initializer present" do
        before do
          create_file(
            File.join(@app_path, "config", "initializers", "rack_attack.rb"),
            "Rack::Attack.throttle('req/ip', limit: 300, period: 5.minutes) { |r| r.ip }\n"
          )
        end

        it "reports the initializer found" do
          result = build_check.run
          expect(result.infos.join).to include("rack_attack.rb")
        end

        it "has no errors" do
          result = build_check.run
          expect(result.errors).to be_empty
        end
      end

      context "without an initializer" do
        it "warns about missing initializer" do
          result = build_check.run
          expect(result.warnings.join).to include("initializer")
        end
      end

      context "without REDIS_URL" do
        around do |ex|
          old = ENV.delete("REDIS_URL")
          ex.run
          ENV["REDIS_URL"] = old if old
        end

        it "warns about missing Redis" do
          result = build_check.run
          expect(result.warnings.join).to include("REDIS_URL")
        end
      end

      context "with REDIS_URL set" do
        around do |ex|
          ENV["REDIS_URL"] = "redis://localhost:6379/0"
          ex.run
          ENV.delete("REDIS_URL")
        end

        it "does not warn about Redis" do
          result = build_check.run
          expect(result.warnings.join).not_to include("REDIS_URL")
        end
      end
    end

    context "when no rate limiting gem is present" do
      before do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "GEM\n  specs:\n    rails (7.1.0)\n"
        )
      end

      it "warns about missing rate limiting gem" do
        result = build_check.run
        expect(result.warnings.join).to include("rate limiting gem")
      end

      it "has no errors" do
        result = build_check.run
        expect(result.errors).to be_empty
      end
    end

    context "when rack-throttle is in Gemfile.lock" do
      before do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "GEM\n  specs:\n    rack-throttle (0.7.0)\n"
        )
      end

      it "detects rack-throttle" do
        result = build_check.run
        expect(result.infos.join).to include("rack-throttle")
      end
    end
  end
end
