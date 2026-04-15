# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::FileDescriptorCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when soft limit is above minimum" do
      it "adds an info message" do
        check = build_check(minimum: 512)
        allow(check).to receive(:read_soft_limit).and_return(4096)
        allow(check).to receive(:read_hard_limit).and_return("unlimited")
        allow(check).to receive(:check_ulimit_available).and_return(nil)

        result = check.run

        expect(result.infos.any? { |i| i.include?("4096") }).to be true
        expect(result.errors).to be_empty
      end
    end

    context "when soft limit is below minimum" do
      it "adds an error" do
        check = build_check(minimum: 2048)
        allow(check).to receive(:read_soft_limit).and_return(256)
        allow(check).to receive(:read_hard_limit).and_return(4096)
        allow(check).to receive(:check_ulimit_available).and_return(nil)

        result = check.run

        expect(result.errors.any? { |e| e.include?("256") }).to be true
        expect(result.errors.any? { |e| e.include?("2048") }).to be true
      end
    end

    context "when soft limit is low but above minimum" do
      it "adds a warning" do
        check = build_check(minimum: 1024, warning_threshold: 0.85)
        allow(check).to receive(:read_soft_limit).and_return(1100)
        allow(check).to receive(:read_hard_limit).and_return(4096)
        allow(check).to receive(:check_ulimit_available).and_return(nil)

        result = check.run

        expect(result.warnings.any? { |w| w.include?("low") }).to be true
      end
    end

    context "when hard limit is below minimum" do
      it "adds a warning about hard limit" do
        check = build_check(minimum: 2048)
        allow(check).to receive(:read_soft_limit).and_return(4096)
        allow(check).to receive(:read_hard_limit).and_return(512)
        allow(check).to receive(:check_ulimit_available).and_return(nil)

        result = check.run

        expect(result.warnings.any? { |w| w.include?("hard limit") }).to be true
      end
    end

    context "when hard limit is unlimited" do
      it "reports unlimited as info" do
        check = build_check(minimum: 1024)
        allow(check).to receive(:read_soft_limit).and_return(4096)
        allow(check).to receive(:read_hard_limit).and_return("unlimited")
        allow(check).to receive(:check_ulimit_available).and_return(nil)

        result = check.run

        expect(result.infos.any? { |i| i.include?("unlimited") }).to be true
        expect(result.errors).to be_empty
      end
    end

    context "with default options" do
      it "uses DEFAULT_MINIMUM" do
        expect(described_class::DEFAULT_MINIMUM).to eq(1024)
      end

      it "uses DEFAULT_WARNING_THRESHOLD" do
        expect(described_class::DEFAULT_WARNING_THRESHOLD).to eq(0.85)
      end
    end
  end
end
