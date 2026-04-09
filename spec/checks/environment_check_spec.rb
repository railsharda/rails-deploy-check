require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::EnvironmentCheck do
  let(:base_env) do
    {
      "SECRET_KEY_BASE" => "a" * 64,
      "DATABASE_URL"    => "postgres://localhost/myapp_production",
      "RAILS_ENV"       => "production"
    }
  end

  def build_check(overrides = {}, extra_config = {})
    described_class.new({ env_source: base_env.merge(overrides) }.merge(extra_config))
  end

  describe "#run" do
    context "when all required variables are set" do
      it "returns no errors" do
        result = build_check.run
        expect(result.errors).to be_empty
      end

      it "adds an info message" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/required environment variables are set/))
      end
    end

    context "when a required variable is missing" do
      it "adds an error for each missing variable" do
        result = build_check({ "SECRET_KEY_BASE" => nil }).run
        expect(result.errors).to include(a_string_matching(/SECRET_KEY_BASE/))
      end

      it "adds an error for empty variable" do
        result = build_check({ "DATABASE_URL" => "  " }).run
        expect(result.errors).to include(a_string_matching(/DATABASE_URL/))
      end
    end

    context "with custom required variables" do
      it "includes custom variables in the check" do
        result = build_check({}, required_env_vars: ["MY_API_KEY"]).run
        expect(result.errors).to include(a_string_matching(/MY_API_KEY/))
      end
    end

    context "RAILS_ENV checks" do
      it "warns when RAILS_ENV is development" do
        result = build_check({ "RAILS_ENV" => "development" }).run
        expect(result.warnings).to include(a_string_matching(/development/))
      end

      it "errors when RAILS_ENV is test" do
        result = build_check({ "RAILS_ENV" => "test" }).run
        expect(result.errors).to include(a_string_matching(/test.*should not be deployed/))
      end

      it "adds info for production RAILS_ENV" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/RAILS_ENV is set to 'production'/))
      end
    end

    context "SECRET_KEY_BASE length" do
      it "warns when SECRET_KEY_BASE is too short" do
        result = build_check({ "SECRET_KEY_BASE" => "short" }).run
        expect(result.warnings).to include(a_string_matching(/SECRET_KEY_BASE appears too short/))
      end
    end
  end
end
