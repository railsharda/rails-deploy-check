# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/smtp_check"

RSpec.describe RailsDeployCheck::Checks::SmtpCheck do
  def build_check(config = {})
    described_class.new(config)
  end

  describe "#run" do
    context "when SMTP_HOST is not set" do
      it "returns an error" do
        check = build_check(host: nil)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SMTP_HOST").and_return(nil)

        result = check.run
        expect(result.errors).to include(a_string_matching(/host is not configured/))
      end
    end

    context "when SMTP_HOST is configured" do
      it "includes host info" do
        check = build_check(host: "smtp.example.com")
        allow(check).to receive(:port_reachable?).and_return(false)

        result = check.run
        expect(result.infos).to include(a_string_matching(/smtp.example.com/))
      end
    end

    context "when port is non-standard" do
      it "adds a warning" do
        check = build_check(host: "smtp.example.com", port: 9999)
        allow(check).to receive(:port_reachable?).and_return(true)

        result = check.run
        expect(result.warnings).to include(a_string_matching(/not a commonly used port/))
      end
    end

    context "when port is standard" do
      it "adds an info message" do
        check = build_check(host: "smtp.example.com", port: 587)
        allow(check).to receive(:port_reachable?).and_return(true)

        result = check.run
        expect(result.infos).to include(a_string_matching(/587/))
      end
    end

    context "when server is reachable" do
      it "adds a success info" do
        check = build_check(host: "smtp.example.com", port: 587)
        allow(check).to receive(:port_reachable?).and_return(true)

        result = check.run
        expect(result.errors).not_to include(a_string_matching(/Cannot reach/))
        expect(result.infos).to include(a_string_matching(/is reachable/))
      end
    end

    context "when server is not reachable" do
      it "adds an error" do
        check = build_check(host: "smtp.example.com", port: 587)
        allow(check).to receive(:port_reachable?).and_return(false)

        result = check.run
        expect(result.errors).to include(a_string_matching(/Cannot reach SMTP server/))
      end
    end

    context "when require_auth is true and credentials missing" do
      it "warns about missing username" do
        check = build_check(host: "smtp.example.com", username: nil, require_auth: true)
        allow(check).to receive(:port_reachable?).and_return(true)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SMTP_USERNAME").and_return(nil)
        allow(ENV).to receive(:[]).with("SMTP_PASSWORD").and_return(nil)

        result = check.run
        expect(result.warnings).to include(a_string_matching(/username not configured/))
      end
    end

    context "when require_auth is false" do
      it "skips credential checks" do
        check = build_check(host: "smtp.example.com", require_auth: false)
        allow(check).to receive(:port_reachable?).and_return(true)

        result = check.run
        expect(result.warnings).not_to include(a_string_matching(/username/))
        expect(result.warnings).not_to include(a_string_matching(/password/))
      end
    end
  end
end
