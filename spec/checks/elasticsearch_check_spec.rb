# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/elasticsearch_check"
require "rails_deploy_check/checks/elasticsearch_check_integration"

RSpec.describe RailsDeployCheck::Checks::ElasticsearchCheck do
  def build_check(config = {})
    described_class.new(config)
  end

  describe "#run" do
    context "when no URL is configured" do
      before { %w[ELASTICSEARCH_URL BONSAI_URL SEARCHBOX_URL].each { |v| ENV.delete(v) } }

      it "returns info when not required" do
        result = build_check(required: false).run
        expect(result.infos).to include(a_string_matching(/skipping check/))
        expect(result.errors).to be_empty
      end

      it "returns error when required" do
        result = build_check(required: true).run
        expect(result.errors).to include(a_string_matching(/No Elasticsearch URL configured/))
      end
    end

    context "when URL is set via ENV" do
      around do |example|
        ENV["ELASTICSEARCH_URL"] = "http://localhost:9200"
        example.run
        ENV.delete("ELASTICSEARCH_URL")
      end

      it "picks up the URL from ELASTICSEARCH_URL" do
        check = build_check
        expect(check.instance_variable_get(:@url)).to eq("http://localhost:9200")
      end
    end

    context "when URL is malformed" do
      it "reports a malformed URL error" do
        result = build_check(url: "not a url").run
        expect(result.errors).to include(a_string_matching(/malformed|not a valid/))
      end
    end

    context "when URL has a non-standard port" do
      it "warns about the non-standard port" do
        stub_request(:get, "http://localhost:9999/").to_return(status: 200, body: "{}")
        result = build_check(url: "http://localhost:9999").run
        expect(result.warnings).to include(a_string_matching(/non-standard port 9999/))
      end
    end

    context "when Elasticsearch is reachable" do
      it "adds an info message" do
        stub_request(:get, "http://localhost:9200/").to_return(status: 200, body: "{}")
        result = build_check(url: "http://localhost:9200").run
        expect(result.infos).to include(a_string_matching(/reachable/))
        expect(result.errors).to be_empty
      end
    end

    context "when Elasticsearch returns a non-200 status" do
      it "adds a warning" do
        stub_request(:get, "http://localhost:9200/").to_return(status: 503, body: "")
        result = build_check(url: "http://localhost:9200").run
        expect(result.warnings).to include(a_string_matching(/HTTP 503/))
      end
    end

    context "when connection is refused" do
      it "adds an error" do
        stub_request(:get, "http://localhost:9200/").to_raise(Errno::ECONNREFUSED)
        result = build_check(url: "http://localhost:9200").run
        expect(result.errors).to include(a_string_matching(/connection refused/))
      end
    end

    context "when connection times out" do
      it "adds an error" do
        stub_request(:get, "http://localhost:9200/").to_raise(Net::OpenTimeout)
        result = build_check(url: "http://localhost:9200").run
        expect(result.errors).to include(a_string_matching(/timed out/))
      end
    end
  end

  describe RailsDeployCheck::Checks::ElasticsearchCheckIntegration do
    describe ".applicable?" do
      before { %w[ELASTICSEARCH_URL BONSAI_URL SEARCHBOX_URL].each { |v| ENV.delete(v) } }

      it "returns true when ELASTICSEARCH_URL is set" do
        ENV["ELASTICSEARCH_URL"] = "http://localhost:9200"
        expect(described_class.applicable?).to be true
        ENV.delete("ELASTICSEARCH_URL")
      end

      it "returns false when no URL and no Gemfile.lock" do
        allow(File).to receive(:exist?).and_return(false)
        expect(described_class.applicable?).to be false
      end
    end
  end
end
