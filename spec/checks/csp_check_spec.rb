require "spec_helper"
require "rails_deploy_check/checks/csp_check"

RSpec.describe RailsDeployCheck::Checks::CspCheck do
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
    context "when secure_headers gem is present in Gemfile.lock" do
      before do
        create_file(File.join(@tmpdir, "Gemfile.lock"), "    secure_headers (6.5.0)\n")
      end

      it "adds an info message about secure_headers" do
        result = build_check.run
        expect(result.infos.join).to include("secure_headers gem found")
      end
    end

    context "when no CSP gem is present" do
      before do
        create_file(File.join(@tmpdir, "Gemfile.lock"), "    rails (7.0.0)\n")
      end

      it "adds a warning about missing CSP gem" do
        result = build_check.run
        expect(result.warnings.join).to include("No CSP gem")
      end
    end

    context "when Gemfile.lock does not exist" do
      it "adds a warning about missing Gemfile.lock" do
        result = build_check.run
        expect(result.warnings.join).to include("Gemfile.lock not found")
      end
    end

    context "when CSP initializer exists" do
      before do
        create_file(File.join(@tmpdir, "Gemfile.lock"), "    secure_headers (6.5.0)\n")
        create_file(
          File.join(@tmpdir, "config", "initializers", "content_security_policy.rb"),
          "Rails.application.config.content_security_policy { |p| p.default_src :self }\n"
        )
      end

      it "adds an info message about the initializer" do
        result = build_check.run
        expect(result.infos.join).to include("CSP initializer found")
      end
    end

    context "when unsafe-inline is used in production" do
      before do
        create_file(File.join(@tmpdir, "Gemfile.lock"), "    secure_headers (6.5.0)\n")
        create_file(
          File.join(@tmpdir, "config", "initializers", "content_security_policy.rb"),
          "p.script_src :self, \"'unsafe-inline'\"\n"
        )
      end

      it "adds a warning about unsafe-inline" do
        result = build_check.run
        expect(result.warnings.join).to include("unsafe-inline")
      end
    end

    context "when rails_env is not production" do
      it "skips the unsafe-inline check" do
        create_file(File.join(@tmpdir, "Gemfile.lock"), "    secure_headers (6.5.0)\n")
        create_file(
          File.join(@tmpdir, "config", "initializers", "content_security_policy.rb"),
          "p.script_src :self, \"'unsafe-inline'\"\n"
        )
        result = build_check(rails_env: "development").run
        expect(result.warnings.join).not_to include("unsafe-inline")
      end
    end
  end
end
