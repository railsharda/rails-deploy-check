# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/smtp_check"
require "rails_deploy_check/checks/smtp_check_integration"

RSpec.describe RailsDeployCheck::Checks::SmtpCheckIntegration do
  describe ".applicable?" do
    context "when SMTP_HOST is set" do
      it "returns true" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SMTP_HOST").and_return("smtp.example.com")

        expect(described_class.applicable?).to be true
      end
    end

    context "when SMTP_HOST is empty" do
      it "returns false" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SMTP_HOST").and_return("")
        allow(described_class).to receive(:rails_smtp_configured?).and_return(false)

        expect(described_class.applicable?).to be false
      end
    end

    context "when SMTP_HOST is nil" do
      it "returns false without Rails" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SMTP_HOST").and_return(nil)
        allow(described_class).to receive(:rails_smtp_configured?).and_return(false)

        expect(described_class.applicable?).to be false
      end
    end
  end

  describe ".build" do
    it "returns a SmtpCheck instance" do
      check = described_class.build(host: "smtp.example.com")
      expect(check).to be_a(RailsDeployCheck::Checks::SmtpCheck)
    end
  end

  describe ".register" do
    it "registers the check when applicable" do
      runner = double("runner")
      allow(described_class).to receive(:applicable?).and_return(true)
      expect(runner).to receive(:register).with(:smtp, an_instance_of(RailsDeployCheck::Checks::SmtpCheck))

      described_class.register(runner)
    end

    it "does not register when not applicable" do
      runner = double("runner")
      allow(described_class).to receive(:applicable?).and_return(false)
      expect(runner).not_to receive(:register)

      described_class.register(runner)
    end
  end
end
