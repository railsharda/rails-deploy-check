# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/readiness_check"

RSpec.describe RailsDeployCheck::Checks::ReadinessCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when no APP_URL is configured" do
      it "returns an info result and does not error" do
        check = build_check(app_url: nil)
        allow(ENV).to receive(:[]).with("APP_URL").and_return(nil)
        allow(ENV).to receive(:[]).with("RAILS_APP_URL").and_return(nil)

        result = check.run
        expect(result.infos).to include(match(/No APP_URL configured/))
        expect(result.errors).to be_empty
      end
    end

    context "when the readiness endpoint responds with 200" do
      it "adds an info message" do
        fake_response = instance_double(Net::HTTPResponse, code: "200")
        check = build_check(app_url: "http://localhost:3000", path: "/healthz")
        allow(check).to receive(:perform_request).and_return(fake_response)

        result = check.run
        expect(result.errors).to be_empty
        expect(result.infos).to include(match(/responded with HTTP 200/))
      end
    end

    context "when the readiness endpoint returns a non-200 status" do
      it "adds an error" do
        fake_response = instance_double(Net::HTTPResponse, code: "503")
        check = build_check(app_url: "http://localhost:3000", path: "/healthz")
        allow(check).to receive(:perform_request).and_return(fake_response)

        result = check.run
        expect(result.errors).to include(match(/returned HTTP 503/))
      end
    end

    context "when the readiness endpoint does not respond" do
      it "adds an error about timeout" do
        check = build_check(app_url: "http://localhost:3000", path: "/healthz", timeout: 1)
        allow(check).to receive(:perform_request).and_return(nil)

        result = check.run
        expect(result.errors).to include(match(/did not respond within/))
      end
    end

    context "when expect_200 is false and endpoint returns 503" do
      it "does not add an error" do
        fake_response = instance_double(Net::HTTPResponse, code: "503")
        check = build_check(app_url: "http://localhost:3000", path: "/healthz", expect_200: false)
        allow(check).to receive(:perform_request).and_return(fake_response)

        result = check.run
        expect(result.errors).to be_empty
        expect(result.infos).to include(match(/responded with HTTP 503/))
      end
    end

    context "when an unexpected exception occurs" do
      it "adds an error with the exception message" do
        check = build_check(app_url: "http://localhost:3000", path: "/healthz")
        allow(check).to receive(:perform_request).and_raise(StandardError, "unexpected failure")

        result = check.run
        expect(result.errors).to include(match(/unexpected failure/))
      end
    end
  end
end
