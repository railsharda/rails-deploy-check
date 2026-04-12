require "spec_helper"
require "rails_deploy_check/checks/headers_check"

RSpec.describe RailsDeployCheck::Checks::HeadersCheck do
  def build_check(options = {})
    described_class.new({ app_path: @app_path }.merge(options))
  end

  def create_file(relative_path, content = "")
    full_path = File.join(@app_path, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @app_path = dir
      example.run
    end
  end

  describe "#run" do
    context "when secure_headers gem is present in Gemfile.lock" do
      before do
        create_file("Gemfile.lock", "    secure_headers (6.5.0)\n")
        FileUtils.mkdir_p(File.join(@app_path, "config", "initializers"))
      end

      it "adds an info message about secure_headers" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/secure_headers gem detected/))
      end
    end

    context "when secure_headers gem is absent from Gemfile.lock" do
      before do
        create_file("Gemfile.lock", "    rails (7.1.0)\n")
        FileUtils.mkdir_p(File.join(@app_path, "config", "initializers"))
      end

      it "adds a warning about missing secure_headers" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/secure_headers gem not found/))
      end
    end

    context "when a security initializer exists" do
      before do
        create_file("Gemfile.lock", "    secure_headers (6.5.0)\n")
        create_file("config/initializers/secure_headers.rb",
                    "SecureHeaders::Configuration.default { |config| config.x_frame_options = \"DENY\" }")
      end

      it "adds an info message about the initializer" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Security headers initializer detected/))
      end
    end

    context "when no security initializer exists" do
      before do
        create_file("Gemfile.lock", "    rails (7.1.0)\n")
        FileUtils.mkdir_p(File.join(@app_path, "config", "initializers"))
      end

      it "adds an error by default" do
        result = build_check.run
        expect(result.errors).to include(a_string_matching(/No security headers initializer found/))
      end

      it "adds a warning when warn_only is true" do
        result = build_check(warn_only: true).run
        expect(result.warnings).to include(a_string_matching(/No security headers initializer found/))
        expect(result.errors).to be_empty
      end
    end

    context "when CSP initializer exists" do
      before do
        create_file("Gemfile.lock", "    secure_headers (6.5.0)\n")
        create_file("config/initializers/content_security_policy.rb", "# CSP config")
        create_file("config/initializers/secure_headers.rb", "SecureHeaders::Configuration.default {}")
      end

      it "adds an info message about CSP" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Content Security Policy initializer found/))
      end
    end

    context "when Gemfile.lock does not exist" do
      it "adds a warning about missing lockfile" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/Gemfile.lock not found/))
      end
    end
  end
end
