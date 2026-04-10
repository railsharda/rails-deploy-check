# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/mail_check"

RSpec.describe RailsDeployCheck::Checks::MailCheck do
  def build_check(env = {})
    described_class.new(env: env)
  end

  describe "#run" do
    context "when no delivery method is set" do
      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(
          a_string_matching(/ACTION_MAILER_DELIVERY_METHOD is not set/)
        )
      end
    end

    context "when an unknown delivery method is set" do
      it "adds a warning" do
        result = build_check("ACTION_MAILER_DELIVERY_METHOD" => "carrier_pigeon").run
        expect(result.warnings).to include(a_string_matching(/Unrecognised delivery method/))
      end
    end

    context "when a known non-smtp delivery method is set" do
      it "adds an info message and no smtp errors" do
        result = build_check(
          "ACTION_MAILER_DELIVERY_METHOD" => "sendmail",
          "MAILER_FROM" => "no-reply@example.com"
        ).run
        expect(result.infos).to include(a_string_matching(/sendmail/))
        expect(result.errors).to be_empty
      end
    end

    context "when smtp is selected but SMTP_HOST is missing" do
      it "adds an error" do
        result = build_check(
          "ACTION_MAILER_DELIVERY_METHOD" => "smtp",
          "MAILER_FROM" => "no-reply@example.com"
        ).run
        expect(result.errors).to include(a_string_matching(/SMTP_HOST.*is not set/))
      end
    end

    context "when smtp is fully configured" do
      it "is successful with info messages" do
        result = build_check(
          "ACTION_MAILER_DELIVERY_METHOD" => "smtp",
          "SMTP_HOST" => "smtp.mailgun.org",
          "SMTP_PORT" => "587",
          "MAILER_FROM" => "app@example.com"
        ).run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
        expect(result.infos).to include(a_string_matching(/smtp.mailgun.org:587/))
      end
    end

    context "when MAILER_FROM is missing" do
      it "adds a warning" do
        result = build_check(
          "ACTION_MAILER_DELIVERY_METHOD" => "sendmail"
        ).run
        expect(result.warnings).to include(a_string_matching(/No default From address/))
      end
    end

    context "when MAILER_FROM is not a valid email" do
      it "adds an error" do
        result = build_check(
          "ACTION_MAILER_DELIVERY_METHOD" => "sendmail",
          "MAILER_FROM" => "not-an-email"
        ).run
        expect(result.errors).to include(a_string_matching(/does not look like a valid email/))
      end
    end

    context "when DEFAULT_FROM_EMAIL is used as fallback" do
      it "accepts the address" do
        result = build_check(
          "ACTION_MAILER_DELIVERY_METHOD" => "sendmail",
          "DEFAULT_FROM_EMAIL" => "hello@example.com"
        ).run
        expect(result.errors).to be_empty
        expect(result.infos).to include(a_string_matching(/hello@example.com/))
      end
    end
  end
end
