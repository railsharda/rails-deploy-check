# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/ssl_certificate_check"

RSpec.describe RailsDeployCheck::Checks::SslCertificateCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def make_cert(not_after:, subject_cn: "example.com")
    cert = OpenSSL::X509::Certificate.new
    cert.not_before = Time.now - 3600
    cert.not_after = not_after
    name = OpenSSL::X509::Name.parse("/CN=#{subject_cn}")
    cert.subject = name
    ext_factory = OpenSSL::X509::ExtensionFactory.new
    ext_factory.subject_certificate = cert
    cert.add_extension(
      ext_factory.create_extension("subjectAltName", "DNS:#{subject_cn}", false)
    )
    cert
  end

  context "when no host is configured" do
    it "returns an info message and passes" do
      check = build_check
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SSL_HOST").and_return(nil)
      allow(ENV).to receive(:[]).with("APP_HOST").and_return(nil)

      result = check.run
      expect(result.passed?).to be true
      expect(result.infos).to include(a_string_matching(/No SSL host configured/))
    end
  end

  context "when host is configured" do
    let(:host) { "example.com" }

    context "when certificate is valid and not expiring soon" do
      it "adds an info message" do
        cert = make_cert(not_after: Time.now + (60 * 86_400))
        check = build_check(host: host)
        allow(check).to receive(:fetch_certificate).and_return(cert)
        allow(OpenSSL::SSL).to receive(:verify_certificate_identity).and_return(true)

        result = check.run
        expect(result.passed?).to be true
        expect(result.infos).to include(a_string_matching(/valid for 59|60 more day/))
      end
    end

    context "when certificate expires within warn threshold" do
      it "adds a warning" do
        cert = make_cert(not_after: Time.now + (20 * 86_400))
        check = build_check(host: host, warn_days: 30, error_days: 7)
        allow(check).to receive(:fetch_certificate).and_return(cert)
        allow(OpenSSL::SSL).to receive(:verify_certificate_identity).and_return(true)

        result = check.run
        expect(result.warnings).to include(a_string_matching(/expires in 1[0-9] day/))
      end
    end

    context "when certificate expires within error threshold" do
      it "adds an error" do
        cert = make_cert(not_after: Time.now + (3 * 86_400))
        check = build_check(host: host, warn_days: 30, error_days: 7)
        allow(check).to receive(:fetch_certificate).and_return(cert)
        allow(OpenSSL::SSL).to receive(:verify_certificate_identity).and_return(true)

        result = check.run
        expect(result.passed?).to be false
        expect(result.errors).to include(a_string_matching(/expires in [0-3] day/))
      end
    end

    context "when hostname does not match certificate" do
      it "adds an error" do
        cert = make_cert(not_after: Time.now + (60 * 86_400), subject_cn: "other.com")
        check = build_check(host: host)
        allow(check).to receive(:fetch_certificate).and_return(cert)
        allow(OpenSSL::SSL).to receive(:verify_certificate_identity).and_return(false)

        result = check.run
        expect(result.errors).to include(a_string_matching(/hostname mismatch/))
      end
    end

    context "when connection times out" do
      it "adds an error" do
        check = build_check(host: host, timeout: 1)
        allow(check).to receive(:fetch_certificate).and_raise(Timeout::Error)

        result = check.run
        expect(result.errors).to include(a_string_matching(/Timed out/))
      end
    end

    context "when SSL error occurs" do
      it "adds an error" do
        check = build_check(host: host)
        allow(check).to receive(:fetch_certificate).and_raise(OpenSSL::SSL::SSLError, "certificate verify failed")

        result = check.run
        expect(result.errors).to include(a_string_matching(/SSL error/))
      end
    end
  end
end
