# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/two_factor_check"

RSpec.describe RailsDeployCheck::Checks::TwoFactorCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(app_path:, env: {})
    described_class.new(app_path: app_path, env: env)
  end

  describe "#run" do
    context "when Gemfile.lock is missing" do
      it "adds a warning about missing lockfile" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("Gemfile.lock not found") }).to be true
        end
      end
    end

    context "when Gemfile.lock contains devise-two-factor" do
      it "reports 2FA gem detected" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    devise-two-factor (4.0.0)\n")
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("devise-two-factor") }).to be true
        end
      end
    end

    context "when Gemfile.lock contains rotp" do
      it "reports rotp gem detected" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    rotp (6.2.0)\n")
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("rotp") }).to be true
        end
      end
    end

    context "when Gemfile.lock has no 2FA gem" do
      it "adds info that no 2FA gem was detected" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "    rails (7.0.0)\n")
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("No 2FA gem detected") }).to be true
        end
      end
    end

    context "when OTP_SECRET_KEY is set" do
      it "reports OTP secret key is present" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "")
          result = build_check(app_path: app_path, env: { "OTP_SECRET_KEY" => "supersecret" }).run
          expect(result.infos.any? { |i| i.include?("OTP secret key") }).to be true
        end
      end
    end

    context "when no OTP secret env var is set" do
      it "adds a warning about missing OTP secret" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "")
          result = build_check(app_path: app_path, env: {}).run
          expect(result.warnings.any? { |w| w.include?("No OTP secret key") }).to be true
        end
      end
    end

    context "when a 2FA initializer exists" do
      it "reports initializer found" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "")
          create_file("#{app_path}/config/initializers/devise_two_factor.rb", "# config")
          result = build_check(app_path: app_path, env: {}).run
          expect(result.infos.any? { |i| i.include?("devise_two_factor.rb") }).to be true
        end
      end
    end

    context "when no 2FA initializer exists" do
      it "adds a warning about missing initializer" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Gemfile.lock", "")
          result = build_check(app_path: app_path, env: {}).run
          expect(result.warnings.any? { |w| w.include?("No 2FA initializer found") }).to be true
        end
      end
    end
  end
end
