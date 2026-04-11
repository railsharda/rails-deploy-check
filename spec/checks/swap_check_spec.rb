# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/swap_check"

RSpec.describe RailsDeployCheck::Checks::SwapCheck do
  def build_check(config = {})
    described_class.new(config)
  end

  describe "#run" do
    context "when free command is unavailable" do
      before do
        allow(Open3).to receive(:capture3).with("free -m").and_raise(Errno::ENOENT)
      end

      it "adds a warning about unsupported platform" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/Could not determine swap space/))
      end
    end

    context "when free command fails" do
      before do
        status = instance_double(Process::Status, success?: false)
        allow(Open3).to receive(:capture3).with("free -m").and_return(["", "", status])
      end

      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/Could not determine swap space/))
      end
    end

    context "when no swap is configured" do
      before do
        status = instance_double(Process::Status, success?: true)
        output = "              total        used        free\nMem:           7982        3241        4741\nSwap:             0           0           0\n"
        allow(Open3).to receive(:capture3).with("free -m").and_return([output, "", status])
      end

      it "adds a warning about missing swap" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/No swap space configured/))
      end
    end

    context "when swap is below minimum threshold" do
      before do
        status = instance_double(Process::Status, success?: true)
        output = "              total        used        free\nMem:           7982        3241        4741\nSwap:           256          10         246\n"
        allow(Open3).to receive(:capture3).with("free -m").and_return([output, "", status])
      end

      it "adds a warning about low swap" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/Swap space is low: 256MB/))
      end
    end

    context "when swap is sufficient and usage is normal" do
      before do
        status = instance_double(Process::Status, success?: true)
        output = "              total        used        free\nMem:           7982        3241        4741\nSwap:          2048         100        1948\n"
        allow(Open3).to receive(:capture3).with("free -m").and_return([output, "", status])
      end

      it "adds info messages" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Swap space available: 2048MB/))
        expect(result.infos).to include(a_string_matching(/Swap usage: 100MB/))
      end

      it "has no errors or warnings" do
        result = build_check.run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
      end
    end

    context "when swap usage exceeds warn threshold" do
      before do
        status = instance_double(Process::Status, success?: true)
        output = "              total        used        free\nMem:           7982        7800         182\nSwap:          2048        1500         548\n"
        allow(Open3).to receive(:capture3).with("free -m").and_return([output, "", status])
      end

      it "warns about high swap usage" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/High swap usage: 1500MB/))
      end
    end

    context "with custom thresholds" do
      before do
        status = instance_double(Process::Status, success?: true)
        output = "              total        used        free\nMem:           7982        3241        4741\nSwap:           512          50         462\n"
        allow(Open3).to receive(:capture3).with("free -m").and_return([output, "", status])
      end

      it "respects custom min_swap_mb" do
        result = build_check(min_swap_mb: 1024).run
        expect(result.warnings).to include(a_string_matching(/Swap space is low: 512MB.*recommended: 1024MB/))
      end
    end
  end
end
