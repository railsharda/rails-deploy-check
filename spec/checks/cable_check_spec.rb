require "spec_helper"
require "rails_deploy_check/checks/cable_check"

RSpec.describe RailsDeployCheck::Checks::CableCheck do
  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when cable.yml does not exist" do
      it "adds a warning" do
        result = build_check(app_path: "/nonexistent").run
        expect(result.warnings).to include(a_string_matching(/cable\.yml not found/))
      end
    end

    context "when cable.yml exists" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/config/cable.yml", "production:\n  adapter: redis\n  url: redis://localhost:6379")
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/cable\.yml found/))
        end
      end
    end

    context "when adapter is configured" do
      it "adds an info message for known adapter" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/config/cable.yml", "production:\n  adapter: redis\n  url: redis://localhost:6379")
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/adapter.*redis.*known adapter/i))
        end
      end

      it "adds a warning for unknown adapter" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/config/cable.yml", "production:\n  adapter: custom_adapter")
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/not a commonly used adapter/))
        end
      end
    end

    context "when no adapter is specified in cable.yml" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/config/cable.yml", "production:\n  url: redis://localhost:6379")
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/No adapter configured/))
        end
      end
    end

    context "when async adapter is used in production" do
      around do |example|
        old_env = ENV["RAILS_ENV"]
        ENV["RAILS_ENV"] = "production"
        example.run
        ENV["RAILS_ENV"] = old_env
      end

      it "adds an error" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/config/cable.yml", "production:\n  adapter: async")
          result = build_check(app_path: app_path).run
          expect(result.errors).to include(a_string_matching(/async.*production/i))
        end
      end
    end

    context "when async adapter is used in development" do
      around do |example|
        old_env = ENV["RAILS_ENV"]
        ENV["RAILS_ENV"] = "development"
        example.run
        ENV["RAILS_ENV"] = old_env
      end

      it "does not add an error" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/config/cable.yml", "development:\n  adapter: async")
          result = build_check(app_path: app_path).run
          expect(result.errors).to be_empty
        end
      end
    end
  end
end
