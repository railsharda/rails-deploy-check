# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/sidekiq_check"

RSpec.describe RailsDeployCheck::Checks::SidekiqCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when sidekiq is available and Redis URL is valid" do
      it "reports info for valid configuration" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "sidekiq.yml"), "---\n:concurrency: 5\n")

          check = build_check(
            app_path: app_path,
            redis_url: "redis://localhost:6379/0"
          )

          allow(check).to receive(:sidekiq_available?).and_return(true)
          result = check.run

          expect(result.errors).to be_empty
          expect(result.infos).to include(match(/Sidekiq gem is available/))
          expect(result.infos).to include(match(/sidekiq.yml/))
          expect(result.infos).to include(match(/redis:\/\/localhost/))
        end
      end
    end

    context "when sidekiq gem is missing" do
      it "adds an error when require_sidekiq is true" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, require_sidekiq: true, redis_url: "redis://localhost:6379/0")
          allow(check).to receive(:sidekiq_available?).and_return(false)
          result = check.run

          expect(result.errors).to include(match(/Sidekiq gem is not available/))
        end
      end

      it "adds a warning when require_sidekiq is false" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, require_sidekiq: false, redis_url: "redis://localhost:6379/0")
          allow(check).to receive(:sidekiq_available?).and_return(false)
          result = check.run

          expect(result.errors).to be_empty
          expect(result.warnings).to include(match(/optional/))
        end
      end
    end

    context "when Redis URL is invalid" do
      it "adds an error for a malformed URL" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, redis_url: "not-a-valid-url")
          allow(check).to receive(:sidekiq_available?).and_return(true)
          result = check.run

          expect(result.errors).to include(match(/does not appear to be a valid Redis URL/))
        end
      end

      it "adds an error when Redis URL is empty" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, redis_url: "")
          allow(check).to receive(:sidekiq_available?).and_return(true)
          result = check.run

          expect(result.errors).to include(match(/REDIS_URL is not configured/))
        end
      end
    end

    context "when no sidekiq config file exists" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, redis_url: "redis://localhost:6379/0")
          allow(check).to receive(:sidekiq_available?).and_return(true)
          result = check.run

          expect(result.warnings).to include(match(/No Sidekiq config file found/))
        end
      end
    end

    context "with check_queues option" do
      it "reports each expected queue" do
        with_tmp_rails_app do |app_path|
          check = build_check(
            app_path: app_path,
            redis_url: "redis://localhost:6379/0",
            check_queues: ["default", "mailers"]
          )
          allow(check).to receive(:sidekiq_available?).and_return(true)
          result = check.run

          expect(result.infos).to include(match(/default/))
          expect(result.infos).to include(match(/mailers/))
        end
      end
    end
  end
end
