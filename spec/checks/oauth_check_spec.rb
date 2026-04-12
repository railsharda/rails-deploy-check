require "spec_helper"
require "rails_deploy_check/checks/oauth_check"

RSpec.describe RailsDeployCheck::Checks::OauthCheck do
  def build_check(options = {})
    described_class.new({ app_path: @app_path, env: {} }.merge(options))
  end

  def create_file(relative_path, content = "")
    full = File.join(@app_path, relative_path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @app_path = dir
      example.run
    end
  end

  describe "#run" do
    context "when Gemfile.lock is missing" do
      it "adds a warning about missing lockfile" do
        result = build_check.run
        expect(result.warnings.map(&:message)).to include(match(/Gemfile.lock not found/))
      end
    end

    context "when Gemfile.lock exists without omniauth" do
      before { create_file("Gemfile.lock", "GEM\n  specs:\n    rails (7.0.0)\n") }

      it "adds an info message that omniauth is not detected" do
        result = build_check.run
        expect(result.infos.map(&:message)).to include(match(/omniauth gem not detected/))
      end
    end

    context "when Gemfile.lock contains omniauth" do
      before { create_file("Gemfile.lock", "GEM\n  specs:\n    omniauth (2.1.0)\n") }

      it "reports omniauth gem found" do
        result = build_check.run
        expect(result.infos.map(&:message)).to include(match(/omniauth gem found/))
      end
    end

    context "with a configured provider" do
      before { create_file("Gemfile.lock", "GEM\n  specs:\n    omniauth (2.1.0)\n") }

      it "passes when all provider env vars are present" do
        env = { "GITHUB_CLIENT_ID" => "id123", "GITHUB_CLIENT_SECRET" => "sec456" }
        result = build_check(providers: ["github"], env: env).run
        expect(result.errors).to be_empty
        expect(result.infos.map(&:message)).to include(match(/github OAuth credentials present/))
      end

      it "errors when provider env vars are missing" do
        result = build_check(providers: ["github"], env: {}).run
        expect(result.errors.map(&:message)).to include(match(/Missing github OAuth environment variables/))
      end

      it "warns for unknown providers" do
        result = build_check(providers: ["myapp"], env: {}).run
        expect(result.warnings.map(&:message)).to include(match(/Unknown OAuth provider 'myapp'/))
      end
    end

    context "callback URL detection" do
      before { create_file("Gemfile.lock", "GEM\n  specs:\n    omniauth (2.1.0)\n") }

      it "warns when no callback URL is set" do
        result = build_check(env: {}).run
        expect(result.warnings.map(&:message)).to include(match(/No callback URL detected/))
      end

      it "reports the callback URL when APP_HOST is present" do
        env = { "APP_HOST" => "https://example.com" }
        result = build_check(env: env).run
        expect(result.infos.map(&:message)).to include(match(/https:\/\/example\.com/))
      end
    end
  end
end
