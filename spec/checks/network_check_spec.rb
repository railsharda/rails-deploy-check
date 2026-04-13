# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/network_check"

RSpec.describe RailsDeployCheck::Checks::NetworkCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when external connectivity is available" do
      before do
        allow_any_instance_of(described_class)
          .to receive(:host_reachable?).and_return(true)
      end

      it "returns a passing result" do
        result = build_check.run
        expect(result.errors).to be_empty
        expect(result.infos).to include(a_string_matching(/External network connectivity confirmed/))
      end
    end

    context "when external connectivity is unavailable" do
      before do
        allow_any_instance_of(described_class)
          .to receive(:host_reachable?).and_return(false)
      end

      it "adds an error" do
        result = build_check.run
        expect(result.errors).to include(a_string_matching(/No external network connectivity/i))
      end
    end

    context "with custom hosts" do
      before do
        allow_any_instance_of(described_class)
          .to receive(:host_reachable?).and_call_original
        allow_any_instance_of(described_class)
          .to receive(:host_reachable?).with("8.8.8.8", 53).and_return(true)
        allow_any_instance_of(described_class)
          .to receive(:host_reachable?).with("mydb.example.com", 5432).and_return(false)
      end

      it "warns when a custom host is unreachable" do
        result = build_check(
          hosts: [{ host: "mydb.example.com", port: 5432, label: "DB host" }]
        ).run
        expect(result.warnings).to include(a_string_matching(/DB host/))
      end

      it "reports info when a custom host is reachable" do
        allow_any_instance_of(described_class)
          .to receive(:host_reachable?).with("mydb.example.com", 5432).and_return(true)

        result = build_check(
          hosts: [{ host: "mydb.example.com", port: 5432, label: "DB host" }]
        ).run
        expect(result.infos).to include(a_string_matching(/DB host/))
      end
    end

    context "with no custom hosts" do
      before do
        allow_any_instance_of(described_class)
          .to receive(:host_reachable?).and_return(true)
      end

      it "does not add custom host messages" do
        result = build_check(hosts: []).run
        expect(result.infos.count).to eq(1)
      end
    end
  end
end
