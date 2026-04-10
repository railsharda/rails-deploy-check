# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::StorageCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new({ app_path: @tmpdir, rails_env: "production" }.merge(options))
  end

  around do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  describe "#run" do
    context "when config/storage.yml is missing" do
      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/storage\.yml not found/))
      end
    end

    context "when config/storage.yml exists" do
      before do
        create_file(File.join(@tmpdir, "config", "storage.yml"), "amazon:\n  service: S3\n")
      end

      it "adds an info message" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/storage\.yml found/))
      end

      context "and the environment config sets the service correctly" do
        before do
          create_file(
            File.join(@tmpdir, "config", "environments", "production.rb"),
            "config.active_storage.service = :amazon\n"
          )
        end

        it "reports the service as defined" do
          result = build_check.run
          expect(result.infos).to include(a_string_matching(/:amazon.*defined in storage\.yml/))
        end

        it "has no errors" do
          result = build_check.run
          expect(result.errors).to be_empty
        end
      end

      context "and the environment config references an undefined service" do
        before do
          create_file(
            File.join(@tmpdir, "config", "environments", "production.rb"),
            "config.active_storage.service = :gcs\n"
          )
        end

        it "adds an error" do
          result = build_check.run
          expect(result.errors).to include(a_string_matching(/:gcs.*not defined/))
        end
      end

      context "and the environment config does not set a service" do
        before do
          create_file(
            File.join(@tmpdir, "config", "environments", "production.rb"),
            "Rails.application.configure do\nend\n"
          )
        end

        it "adds a warning" do
          result = build_check.run
          expect(result.warnings).to include(a_string_matching(/active_storage\.service not set/))
        end
      end
    end

    context "when activestorage is in Gemfile.lock but migrations are missing" do
      before do
        create_file(File.join(@tmpdir, "config", "storage.yml"), "local:\n  service: Disk\n")
        create_file(File.join(@tmpdir, "Gemfile.lock"), "    activestorage (7.0.0)\n")
        FileUtils.mkdir_p(File.join(@tmpdir, "db", "migrate"))
      end

      it "adds a warning about missing migrations" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/migrations not found/))
      end
    end

    context "when Active Storage migrations are present" do
      before do
        create_file(File.join(@tmpdir, "config", "storage.yml"), "local:\n  service: Disk\n")
        create_file(
          File.join(@tmpdir, "db", "migrate", "20230101000000_create_active_storage_tables.rb"),
          "# migration"
        )
      end

      it "adds an info message" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Active Storage migrations are present/))
      end
    end
  end
end
