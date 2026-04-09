require "spec_helper"
require "rails_deploy_check/checks/ssl_check"

RSpec.describe RailsDeployCheck::Checks::SslCheck do
  def build_check(config = {})
    described_class.new(config)
  end

  describe "#run" do
    context "when no host is configured" do
      it "returns an error result" do
        result = build_check.run
        expect(result.errors).to include(match(/No host configured/))
      end

      it "does not attempt a connection" do
        check = build_check
        expect(check).not_to receive(:fetch_certificate)
        check.run
      end
    end

    context "when host is an empty string" do
      it "returns an error result" do
        result = build_check(host: "  ").run
        expect(result.errors).to include(match(/No host configured/))
      end
    end

    context "when connection is refused" do
      before do
        allow_any_instance_of(described_class).to receive(:fetch_certificate)
          .and_raise(Errno::ECONNREFUSED)
      end

      it "reports a connection refused error" do
        result = build_check(host: "example.com").run
        expect(result.errors).to include(match(/Connection refused/))
      end
    end

    context "when connection times out" do
      before do
        allow_any_instance_of(described_class).to receive(:fetch_certificate)
          .and_raise(Errno::ETIMEDOUT)
      end

      it "reports a timeout error" do
        result = build_check(host: "example.com").run
        expect(result.errors).to include(match(/timed out/))
      end
    end

    context "when certificate is nil" do
      before do
        allow_any_instance_of(described_class).to receive(:fetch_certificate).and_return(nil)
      end

      it "reports that the certificate could not be retrieved" do
        result = build_check(host: "example.com").run
        expect(result.errors).to include(match(/Could not retrieve SSL certificate/))
      end
    end

    context "when certificate is valid and not expiring soon" do
      let(:cert) do
        double(
          not_after: Time.now + (60 * 86_400),
          subject: double(to_s: "/CN=example.com")
        )
      end

      before do
        allow_any_instance_of(described_class).to receive(:fetch_certificate).and_return(cert)
        allow(OpenSSL::SSL).to receive(:verify_certificate_identity).and_return(true)
      end

      it "adds an info message" do
        result = build_check(host: "example.com").run
        expect(result.infos).to include(match(/valid for 60 more day/))
      end

      it "has no errors or warnings" do
        result = build_check(host: "example.com").run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
      end
    end

    context "when certificate expires within warning threshold" do
      let(:cert) { double(not_after: Time.now + (20 * 86_400)) }

      before do
        allow_any_instance_of(described_class).to receive(:fetch_certificate).and_return(cert)
        allow(OpenSSL::SSL).to receive(:verify_certificate_identity).and_return(true)
      end

      it "adds a warning" do
        result = build_check(host: "example.com").run
        expect(result.warnings).to include(match(/expires in \d+ day/))
      end
    end

    context "when certificate expires within critical threshold" do
      let(:cert) { double(not_after: Time.now + (5 * 86_400)) }

      before do
        allow_any_instance_of(described_class).to receive(:fetch_certificate).and_return(cert)
        allow(OpenSSL::SSL).to receive(:verify_certificate_identity).and_return(true)
      end

      it "adds an error" do
        result = build_check(host: "example.com").run
        expect(result.errors).to include(match(/expires in \d+ day/))
      end
    end

    context "when certificate hostname does not match" do
      let(:cert) { double(not_after: Time.now + (60 * 86_400)) }

      before do
        allow_any_instance_of(described_class).to receive(:fetch_certificate).and_return(cert)
        allow(OpenSSL::SSL).to receive(:verify_certificate_identity).and_return(false)
      end

      it "adds a hostname mismatch error" do
        result = build_check(host: "example.com").run
        expect(result.errors).to include(match(/hostname mismatch/))
      end
    end
  end
end
