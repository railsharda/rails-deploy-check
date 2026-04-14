# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/tls_version_check"

RSpec.describe RailsDeployCheck::Checks::TlsVersionCheck do
  def build_check(host: nil, port: 443, warn_on_tls12: false)
    described_class.new(host: host, port: port, warn_on_tls12: warn_on_tls12)
  end

  describe "#run" do
    context "when no host is configured" do
      it "returns an info result and skips checks" do
        check = build_check(host: nil)
        allow(ENV).to receive(:[]).with("SSL_HOST").and_return(nil)
        allow(ENV).to receive(:[]).with("APP_HOST").and_return(nil)

        result = check.run

        expect(result.infos).to include(a_string_matching(/No host configured/))
        expect(result.errors).to be_empty
      end
    end

    context "when host is an empty string" do
      it "skips checks and returns info" do
        check = build_check(host: "   ")
        result = check.run
        expect(result.infos).to include(a_string_matching(/No host configured/))
      end
    end

    context "when TLS 1.2 connection succeeds" do
      it "adds an info message confirming TLS 1.2+ support" do
        check = build_check(host: "example.com")
        allow(check).to receive(:attempt_connection).and_return(true)

        result = check.run

        expect(result.infos).to include(a_string_matching(/TLS 1\.2\+ is supported/))
      end
    end

    context "when TLS 1.2 connection fails" do
      it "adds an error for missing TLS 1.2 support" do
        check = build_check(host: "old.example.com")
        allow(check).to receive(:attempt_connection).and_return(false)

        result = check.run

        expect(result.errors).to include(a_string_matching(/Could not establish TLS 1\.2/))
      end
    end

    context "when TLS 1.3 is supported" do
      it "adds an info message confirming TLS 1.3 support" do
        check = build_check(host: "modern.example.com")
        allow(check).to receive(:attempt_connection).and_return(true)

        result = check.run

        expect(result.infos).to include(a_string_matching(/TLS 1\.3 is supported/))
      end
    end

    context "when warn_on_tls12 is true and TLS 1.3 is unavailable" do
      it "adds a warning about TLS 1.3 not being available" do
        check = build_check(host: "tls12only.example.com", warn_on_tls12: true)
        call_count = 0
        allow(check).to receive(:attempt_connection) do
          call_count += 1
          call_count == 1 # first call (TLS 1.2) succeeds, rest fail
        end

        result = check.run

        expect(result.warnings).to include(a_string_matching(/TLS 1\.3 is not available/))
      end
    end

    context "when SSL_HOST env var is set" do
      it "uses the env var as the host" do
        with_env("SSL_HOST" => "env-host.example.com") do
          check = described_class.new
          allow(check).to receive(:attempt_connection).and_return(true)
          result = check.run
          expect(result.infos).to include(a_string_matching(/env-host\.example\.com/))
        end
      end
    end
  end

  def with_env(vars)
    old = vars.transform_values { |_| ENV[_] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    vars.each_key { |k| old[k] ? ENV[k] = old[k] : ENV.delete(k) }
  end
end
