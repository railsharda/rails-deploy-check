# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::QueueCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe "#run" do
    context "when no adapter is configured" do
      it "adds a warning about missing explicit configuration" do
        check = build_check(app_path: "/nonexistent")
        result = check.run
        expect(result.warnings.any? { |w| w.include?("No queue adapter explicitly configured") }).to be true
      end

      it "warns that the default async adapter will be used" do
        check = build_check(app_path: "/nonexistent", warn_on_async: true)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("async") }).to be true
      end
    end

    context "when QUEUE_ADAPTER env var is set" do
      around do |example|
        old = ENV["QUEUE_ADAPTER"]
        ENV["QUEUE_ADAPTER"] = "sidekiq"
        example.run
        ENV["QUEUE_ADAPTER"] = old
      end

      it "detects the adapter from the environment" do
        result = build_check.run
        expect(result.info.any? { |i| i.include?("sidekiq") }).to be true
      end

      it "does not warn about async adapter" do
        result = build_check.run
        expect(result.warnings.none? { |w| w.include?("async") }).to be true
      end
    end

    context "when ACTIVE_JOB_QUEUE_ADAPTER env var is set to inline" do
      around do |example|
        old = ENV["ACTIVE_JOB_QUEUE_ADAPTER"]
        ENV["ACTIVE_JOB_QUEUE_ADAPTER"] = "inline"
        example.run
        ENV["ACTIVE_JOB_QUEUE_ADAPTER"] = old
      end

      it "warns about inline adapter" do
        result = build_check(warn_on_inline: true).run
        expect(result.warnings.any? { |w| w.include?("inline") }).to be true
      end

      it "does not warn when warn_on_inline is false" do
        result = build_check(warn_on_inline: false).run
        expect(result.warnings.none? { |w| w.include?("synchronously") }).to be true
      end
    end

    context "when adapter is configured in application.rb" do
      it "reads the adapter from config/application.rb" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "application.rb"),
            "config.active_job.queue_adapter = :good_job\n"
          )
          result = build_check(app_path: app_path).run
          expect(result.info.any? { |i| i.include?("good_job") }).to be true
        end
      end

      it "warns when an unknown adapter is specified" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "application.rb"),
            "config.active_job.queue_adapter = :my_custom_adapter\n"
          )
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("Unknown queue adapter") }).to be true
        end
      end
    end
  end
end
