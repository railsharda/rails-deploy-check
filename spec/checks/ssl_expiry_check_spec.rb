# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/ssl_expiry_check"

RSpec.describe RailsDeployCheck::Checks::SslExpiryCheck do
  def build_check(host: "example.com", port: 443, warning_days: 30, critical_days: 7)
    described_class.new(host: host, port: port, warning_days: warning_days, critical_days: critical_days)
  end

  def make_cert(not_after:)
    cert = instance_double(OpenSSL::X509::Certificate, not_after: not_after)
    cert
  end

  describe "#run" do
    context "when host is not configured" do
      it "returns an error" do
        check = described_class.new(host: "")
        result = check.run
        expect(result.errors).to include(a_string_matching(/No host configured/))
      end

      it "returns an error for nil host" do
        check = described_class.new(host: nil)
        result = check.run
        expect(result.errors).to include(a_string_matching(/No host configured/))
      end
    end

    context "when certificate cannot be fetched" do
      it "adds a warning" do
        check = build_check(host: "unreachable.example.com")
        allow(check).to receive(:fetch_certificate).and_return(nil)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/Could not retrieve SSL certificate/))
      end
    end

    context "when certificate is expired" do
      it "adds an error" do
        check = build_check(host: "expired.example.com")
        cert = make_cert(not_after: Time.now - (10 * 86_400))
        allow(check).to receive(:fetch_certificate).and_return(cert)
        result = check.run
        expect(result.errors).to include(a_string_matching(/has expired/))
      end
    end

    context "when certificate expires within critical threshold" do
      it "adds an error" do
        check = build_check(host: "critical.example.com", critical_days: 7)
        cert = make_cert(not_after: Time.now + (5 * 86_400))
        allow(check).to receive(:fetch_certificate).and_return(cert)
        result = check.run
        expect(result.errors).to include(a_string_matching(/critical threshold/))
      end
    end

    context "when certificate expires within warning threshold" do
      it "adds a warning" do
        check = build_check(host: "warning.example.com", warning_days: 30, critical_days: 7)
        cert = make_cert(not_after: Time.now + (20 * 86_400))
        allow(check).to receive(:fetch_certificate).and_return(cert)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/consider renewing soon/))
      end
    end

    context "when certificate is valid and not near expiry" do
      it "adds an info message" do
        check = build_check(host: "healthy.example.com")
        cert = make_cert(not_after: Time.now + (90 * 86_400))
        allow(check).to receive(:fetch_certificate).and_return(cert)
        result = check.run
        expect(result.infos).to include(a_string_matching(/is valid for/))
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
      end
    end

    context "when an unexpected error occurs" do
      it "adds a warning" do
        check = build_check(host: "error.example.com")
        allow(check).to receive(:fetch_certificate).and_raise(StandardError, "unexpected")
        result = check.run
        expect(result.warnings).to include(a_string_matching(/SSL expiry check failed/))
      end
    end
  end
end
