# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/external_services_check"

RSpec.describe RailsDeployCheck::Checks::ExternalServicesCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  around do |example|
    original = ENV.to_h
    example.run
    ENV.replace(original)
  end

  describe "#run" do
    context "with no required services and no env vars set" do
      it "returns a passing result" do
        RailsDeployCheck::Checks::ExternalServicesCheck::KNOWN_SERVICES.keys.each do |k|
          ENV.delete(k)
        end
        result = build_check.run
        expect(result).not_to be_failed
        expect(result.infos).to include(a_string_matching(/No well-known external service credentials detected/))
      end
    end

    context "with required services present" do
      it "adds info when required service key is set" do
        ENV["MY_API_KEY"] = "abc123"
        result = build_check(required_services: ["MY_API_KEY"]).run
        expect(result).not_to be_failed
        expect(result.infos).to include(a_string_matching(/MY_API_KEY/))
      end

      it "adds error when required service key is missing" do
        ENV.delete("MY_MISSING_KEY")
        result = build_check(required_services: ["MY_MISSING_KEY"]).run
        expect(result).to be_failed
        expect(result.errors).to include(a_string_matching(/MY_MISSING_KEY/))
      end

      it "adds error when required service key is blank" do
        ENV["MY_BLANK_KEY"] = "   "
        result = build_check(required_services: ["MY_BLANK_KEY"]).run
        expect(result).to be_failed
        expect(result.errors).to include(a_string_matching(/MY_BLANK_KEY/))
      end
    end

    context "with Stripe partial credentials" do
      it "warns when only STRIPE_SECRET_KEY is set" do
        ENV["STRIPE_SECRET_KEY"] = "sk_live_abc"
        ENV.delete("STRIPE_PUBLISHABLE_KEY")
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/STRIPE_PUBLISHABLE_KEY is missing/))
      end

      it "warns when only STRIPE_PUBLISHABLE_KEY is set" do
        ENV.delete("STRIPE_SECRET_KEY")
        ENV["STRIPE_PUBLISHABLE_KEY"] = "pk_live_abc"
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/STRIPE_SECRET_KEY is missing/))
      end

      it "does not warn when both Stripe keys are set" do
        ENV["STRIPE_SECRET_KEY"] = "sk_live_abc"
        ENV["STRIPE_PUBLISHABLE_KEY"] = "pk_live_abc"
        result = build_check.run
        expect(result.warnings).not_to include(a_string_matching(/Stripe/))
      end
    end

    context "with Twilio partial credentials" do
      it "warns when only TWILIO_ACCOUNT_SID is set" do
        ENV["TWILIO_ACCOUNT_SID"] = "ACxxx"
        ENV.delete("TWILIO_AUTH_TOKEN")
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/TWILIO_AUTH_TOKEN is missing/))
      end

      it "warns when only TWILIO_AUTH_TOKEN is set" do
        ENV.delete("TWILIO_ACCOUNT_SID")
        ENV["TWILIO_AUTH_TOKEN"] = "token123"
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/TWILIO_ACCOUNT_SID is missing/))
      end
    end

    context "with known service detected" do
      it "adds info for detected service" do
        ENV["SENDGRID_API_KEY"] = "SG.abc"
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/SendGrid/))
      end
    end
  end
end
