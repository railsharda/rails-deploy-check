# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/uptime_check"

RSpec.describe RailsDeployCheck::Checks::UptimeCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when no URL is configured" do
      it "adds a warning" do
        check = build_check(url: nil)
        allow(ENV).to receive(:[]).with("UPTIME_CHECK_URL").and_return(nil)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/No uptime check URL configured/))
      end
    end

    context "when URL is empty string" do
      it "adds a warning" do
        result = build_check(url: "  ").run
        expect(result.warnings).to include(a_string_matching(/No uptime check URL configured/))
      end
    end

    context "when URL is invalid" do
      it "adds an error" do
        result = build_check(url: "not a valid url !!").run
        expect(result.errors).to include(a_string_matching(/invalid/))
      end
    end

    context "when endpoint is reachable" do
      it "adds info for a 2xx response" do
        stub_response = instance_double(Net::HTTPResponse, code: "200")
        allow_any_instance_of(Net::HTTP).to receive(:get).and_return(stub_response)

        result = build_check(url: "http://example.com/health").run
        expect(result.errors).to be_empty
        expect(result.infos).to include(a_string_matching(/reachable.*HTTP 200/i))
      end

      it "adds info for a 3xx response" do
        stub_response = instance_double(Net::HTTPResponse, code: "301")
        allow_any_instance_of(Net::HTTP).to receive(:get).and_return(stub_response)

        result = build_check(url: "http://example.com").run
        expect(result.errors).to be_empty
      end

      it "adds an error for a 5xx response" do
        stub_response = instance_double(Net::HTTPResponse, code: "503")
        allow_any_instance_of(Net::HTTP).to receive(:get).and_return(stub_response)

        result = build_check(url: "http://example.com").run
        expect(result.errors).to include(a_string_matching(/non-success status.*503/))
      end
    end

    context "when expected_status is provided" do
      it "passes when response matches expected status" do
        stub_response = instance_double(Net::HTTPResponse, code: "200")
        allow_any_instance_of(Net::HTTP).to receive(:get).and_return(stub_response)

        result = build_check(url: "http://example.com", expected_status: 200).run
        expect(result.errors).to be_empty
        expect(result.infos).to include(a_string_matching(/expected status 200/))
      end

      it "fails when response does not match expected status" do
        stub_response = instance_double(Net::HTTPResponse, code: "404")
        allow_any_instance_of(Net::HTTP).to receive(:get).and_return(stub_response)

        result = build_check(url: "http://example.com", expected_status: 200).run
        expect(result.errors).to include(a_string_matching(/expected 200/))
      end
    end

    context "when endpoint times out" do
      it "adds a timeout error" do
        allow_any_instance_of(Net::HTTP).to receive(:get).and_raise(Net::OpenTimeout)

        result = build_check(url: "http://example.com", timeout: 5).run
        expect(result.errors).to include(a_string_matching(/timed out after 5s/))
      end
    end

    context "when endpoint is unreachable" do
      it "adds a socket error" do
        allow_any_instance_of(Net::HTTP).to receive(:get).and_raise(SocketError, "getaddrinfo: Name or service not known")

        result = build_check(url: "http://nonexistent.example.com").run
        expect(result.errors).to include(a_string_matching(/Could not reach endpoint/))
      end
    end
  end
end
