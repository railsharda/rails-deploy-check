# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/memory_check"

RSpec.describe RailsDeployCheck::Checks::MemoryCheck do
  def build_check(config = {})
    described_class.new(config)
  end

  describe "#run" do
    context "when memory is above all thresholds" do
      it "passes with info message" do
        check = build_check(minimum_mb: 128, warning_mb: 256)
        allow(check).to receive(:available_memory_mb).and_return(1024)

        result = check.run

        expect(result.passed?).to be true
        expect(result.infos).to include(match(/1024 MB/))
      end
    end

    context "when memory is below minimum threshold" do
      it "adds an error" do
        check = build_check(minimum_mb: 512, warning_mb: 1024)
        allow(check).to receive(:available_memory_mb).and_return(200)

        result = check.run

        expect(result.passed?).to be false
        expect(result.errors).to include(match(/below minimum threshold/))
        expect(result.errors.first).to include("200 MB")
        expect(result.errors.first).to include("512 MB")
      end
    end

    context "when memory is between minimum and warning thresholds" do
      it "adds a warning" do
        check = build_check(minimum_mb: 128, warning_mb: 512)
        allow(check).to receive(:available_memory_mb).and_return(300)

        result = check.run

        expect(result.passed?).to be true
        expect(result.warnings).to include(match(/below recommended threshold/))
        expect(result.warnings.first).to include("300 MB")
        expect(result.warnings.first).to include("512 MB")
      end
    end

    context "when memory cannot be determined" do
      it "adds a warning about unknown memory" do
        check = build_check
        allow(check).to receive(:available_memory_mb).and_return(nil)

        result = check.run

        expect(result.passed?).to be true
        expect(result.warnings).to include(match(/Could not determine available memory/))
      end
    end

    context "with default thresholds" do
      it "uses 256 MB minimum and 512 MB warning" do
        check = build_check
        allow(check).to receive(:available_memory_mb).and_return(400)

        result = check.run

        expect(result.warnings).to include(match(/below recommended threshold/))
        expect(result.errors).to be_empty
      end
    end
  end
end
