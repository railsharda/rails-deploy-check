# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/load_average_check"

RSpec.describe RailsDeployCheck::Checks::LoadAverageCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when load average is normal" do
      it "adds an info message" do
        check = build_check(warning_threshold: 2.0, critical_threshold: 4.0)
        allow(check).to receive(:read_load_averages).and_return([0.5, 0.4, 0.3])
        allow(check).to receive(:detect_cpu_count).and_return(4)

        result = check.run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
        expect(result.infos).to include(match(/normal/))
      end
    end

    context "when load average exceeds warning threshold" do
      it "adds a warning" do
        check = build_check(warning_threshold: 2.0, critical_threshold: 4.0)
        allow(check).to receive(:read_load_averages).and_return([2.5, 2.0, 1.8])
        allow(check).to receive(:detect_cpu_count).and_return(4)

        result = check.run
        expect(result.warnings).to include(match(/elevated/))
        expect(result.errors).to be_empty
      end
    end

    context "when load average exceeds critical threshold" do
      it "adds an error" do
        check = build_check(warning_threshold: 2.0, critical_threshold: 4.0)
        allow(check).to receive(:read_load_averages).and_return([5.0, 4.5, 4.0])
        allow(check).to receive(:detect_cpu_count).and_return(4)

        result = check.run
        expect(result.errors).to include(match(/critically high/))
      end
    end

    context "when load exceeds cpu count" do
      it "adds a warning about load/cpu ratio" do
        check = build_check(warning_threshold: 2.0, critical_threshold: 4.0)
        allow(check).to receive(:read_load_averages).and_return([3.0, 2.5, 2.0])
        allow(check).to receive(:detect_cpu_count).and_return(2)

        result = check.run
        expect(result.warnings).to include(match(/exceeds CPU count/))
      end
    end

    context "when load averages cannot be determined" do
      it "adds a warning" do
        check = build_check
        allow(check).to receive(:read_load_averages).and_return(nil)

        result = check.run
        expect(result.warnings).to include(match(/Could not determine/))
      end
    end

    context "with default thresholds" do
      it "uses DEFAULT_WARNING_THRESHOLD and DEFAULT_CRITICAL_THRESHOLD" do
        expect(described_class::DEFAULT_WARNING_THRESHOLD).to eq(2.0)
        expect(described_class::DEFAULT_CRITICAL_THRESHOLD).to eq(4.0)
      end
    end
  end
end
