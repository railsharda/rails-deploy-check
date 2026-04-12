# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/https_redirect_check"

RSpec.describe RailsDeployCheck::Checks::HttpsRedirectCheck do
  def build_check(options = {})
    described_class.new({ app_root: @tmpdir, rails_env: "production" }.merge(options))
  end

  def create_file(relative_path, content)
    full_path = File.join(@tmpdir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  describe "#run" do
    context "when force_ssl is enabled" do
      it "adds an info message" do
        create_file("config/environments/production.rb", "config.force_ssl = true\n")
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/force_ssl is enabled/))
        expect(result.errors).to be_empty
      end
    end

    context "when force_ssl is explicitly disabled" do
      it "adds an error" do
        create_file("config/environments/production.rb", "config.force_ssl = false\n")
        result = build_check.run
        expect(result.errors).to include(a_string_matching(/explicitly disabled/))
      end
    end

    context "when force_ssl is not set" do
      it "adds a warning" do
        create_file("config/environments/production.rb", "config.log_level = :info\n")
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/not explicitly set/))
      end
    end

    context "when config file does not exist" do
      it "adds a warning about missing config" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/No production.rb config found/))
      end
    end

    context "when asset_host uses http://" do
      it "adds an error about mixed content" do
        create_file("config/environments/production.rb",
          "config.force_ssl = true\nconfig.action_controller.asset_host = 'http://cdn.example.com'\n")
        result = build_check.run
        expect(result.errors).to include(a_string_matching(/asset_host is configured with http:\/\//i))
      end
    end

    context "when asset_host uses https://" do
      it "adds an info message" do
        create_file("config/environments/production.rb",
          "config.force_ssl = true\nconfig.action_controller.asset_host = 'https://cdn.example.com'\n")
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/asset_host uses a secure scheme/))
        expect(result.errors).to be_empty
      end
    end
  end
end
