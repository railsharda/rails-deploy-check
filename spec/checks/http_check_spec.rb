require "spec_helper"
require "net/http"

RSpec.describe RailsDeployCheck::Checks::HttpCheck do
  def build_check(config = {})
    described_class.new(config)
  end

  describe "#run" do
    context "when app_url is not configured" do
      it "returns a warning and no errors" do
        result = build_check.run
        expect(result.warnings).not_to be_empty
        expect(result.errors).to be_empty
      end
    end

    context "when app_url is configured" do
      let(:url) { "http://example.com" }
      let(:mock_response) { instance_double(Net::HTTPResponse, code: "200") }

      before do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:get).and_return(mock_response)
      end

      it "reports info for a 200 response" do
        result = build_check(app_url: url).run
        expect(result.errors).to be_empty
        expect(result.infos.first).to include("200")
      end

      it "reports an error for a 500 response" do
        allow(mock_response).to receive(:code).and_return("500")
        result = build_check(app_url: url).run
        expect(result.errors.first).to include("500")
      end

      it "checks multiple endpoints" do
        result = build_check(app_url: url, endpoints: ["/", "/health"]).run
        expect(result.infos.size).to eq(2)
      end

      it "reports an error on SocketError" do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:get).and_raise(SocketError, "getaddrinfo: Name or service not known")
        result = build_check(app_url: url).run
        expect(result.errors.first).to include("Cannot reach")
      end

      it "reports an error on timeout" do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:get).and_raise(Net::ReadTimeout)
        result = build_check(app_url: url).run
        expect(result.errors.first).to include("timed out")
      end
    end
  end
end
