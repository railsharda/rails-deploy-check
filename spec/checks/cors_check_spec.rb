# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/cors_check"

RSpec.describe RailsDeployCheck::Checks::CorsCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when Gemfile.lock is missing" do
      it "adds an info message about skipping CORS gem check" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/Gemfile.lock not found/))
        end
      end
    end

    context "when Gemfile.lock exists with rack-cors" do
      it "adds an info message about CORS gem detected" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "    rack-cors (2.0.1)\n")
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/CORS gem detected/))
        end
      end
    end

    context "when Gemfile.lock exists without a CORS gem" do
      it "adds a warning about missing CORS gem" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "    rails (7.1.0)\n")
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/No CORS gem/))
        end
      end
    end

    context "when CORS initializer exists" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "initializers", "cors.rb"), "# cors config")
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/CORS initializer found/))
        end
      end
    end

    context "when CORS initializer is missing" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/No CORS initializer found/))
        end
      end
    end

    context "when CORS initializer uses wildcard origin" do
      it "adds a warning about wildcard origin" do
        with_tmp_rails_app do |app_path|
          cors_content = "Rails.application.config.middleware.insert_before 0, Rack::Cors do\n  allow do\n    origins '*'\n  end\nend\n"
          create_file(File.join(app_path, "config", "initializers", "cors.rb"), cors_content)
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/Wildcard origin/))
        end
      end

      it "adds info when allowed_origins override is set" do
        with_tmp_rails_app do |app_path|
          cors_content = "origins '*'\n"
          create_file(File.join(app_path, "config", "initializers", "cors.rb"), cors_content)
          result = build_check(app_path: app_path, allowed_origins: ["https://example.com"]).run
          expect(result.infos).to include(a_string_matching(/allowed_origins override is configured/))
        end
      end
    end

    context "when CORS initializer uses restricted origins" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          cors_content = "origins 'https://example.com'\n"
          create_file(File.join(app_path, "config", "initializers", "cors.rb"), cors_content)
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/origins appear to be restricted/))
        end
      end
    end
  end
end
