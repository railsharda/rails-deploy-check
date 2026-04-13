require "spec_helper"
require "rails_deploy_check/checks/api_rate_limit_check"

RSpec.describe RailsDeployCheck::Checks::ApiRateLimitCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(app_path)
    described_class.new(app_path: app_path)
  end

  around do |example|
    with_tmp_rails_app do |app_path|
      @app_path = app_path
      example.run
    end
  end

  subject(:check) { build_check(@app_path) }

  describe "#run" do
    context "when Gemfile.lock is missing" do
      it "adds a warning about missing lockfile" do
        result = check.run
        expect(result.warnings).to include(match(/Gemfile.lock not found/))
      end
    end

    context "when Gemfile.lock exists with rack-attack" do
      before do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "GEM\n  specs:\n    rack-attack (6.7.0)\n"
        )
      end

      it "adds an info message about the detected gem" do
        result = check.run
        expect(result.infos).to include(match(/rack-attack/))
      end

      it "has no errors" do
        result = check.run
        expect(result.errors).to be_empty
      end
    end

    context "when Gemfile.lock exists without any rate-limiting gem" do
      before do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "GEM\n  specs:\n    rails (7.1.0)\n"
        )
      end

      it "warns about missing rate-limiting gem" do
        result = check.run
        expect(result.warnings).to include(match(/No rate-limiting gem detected/))
      end
    end

    context "when a retry gem is present" do
      before do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "GEM\n  specs:\n    rack-attack (6.7.0)\n    retriable (3.1.2)\n"
        )
      end

      it "confirms retry gem presence" do
        result = check.run
        expect(result.infos).to include(match(/retriable/))
      end
    end

    context "when no retry gem is present" do
      before do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "GEM\n  specs:\n    rails (7.1.0)\n"
        )
      end

      it "warns about missing retry gem" do
        result = check.run
        expect(result.warnings).to include(match(/No retry gem detected/))
      end
    end

    context "when an API client initializer exists" do
      before do
        create_file(
          File.join(@app_path, "Gemfile.lock"),
          "GEM\n  specs:\n    rails (7.1.0)\n"
        )
        create_file(
          File.join(@app_path, "config", "initializers", "stripe.rb"),
          "Stripe.api_key = ENV['STRIPE_SECRET_KEY']\n"
        )
      end

      it "detects the API client initializer" do
        result = check.run
        expect(result.infos).to include(match(/stripe\.rb/))
      end
    end
  end
end
