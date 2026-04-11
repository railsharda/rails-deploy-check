require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::CpuCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when CPU usage is normal" do
      it "adds an info message" do
        check = build_check(warning_threshold: 80.0, critical_threshold: 95.0)
        allow(check).to receive(:current_cpu_usage).and_return(45.0)
        allow(check).to receive(:cpu_count).and_return(4)

        result = check.run

        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
        expect(result.infos).to include(match(/CPU usage is normal: 45.0%/))
      end
    end

    context "when CPU usage exceeds warning threshold" do
      it "adds a warning message" do
        check = build_check(warning_threshold: 80.0, critical_threshold: 95.0)
        allow(check).to receive(:current_cpu_usage).and_return(85.0)
        allow(check).to receive(:cpu_count).and_return(4)

        result = check.run

        expect(result.errors).to be_empty
        expect(result.warnings).to include(match(/CPU usage is elevated: 85.0%/))
      end
    end

    context "when CPU usage exceeds critical threshold" do
      it "adds an error message" do
        check = build_check(warning_threshold: 80.0, critical_threshold: 95.0)
        allow(check).to receive(:current_cpu_usage).and_return(97.5)
        allow(check).to receive(:cpu_count).and_return(4)

        result = check.run

        expect(result.errors).to include(match(/CPU usage is critically high: 97.5%/))
      end
    end

    context "when CPU usage cannot be determined" do
      it "adds a warning about unsupported platform" do
        check = build_check
        allow(check).to receive(:current_cpu_usage).and_return(nil)
        allow(check).to receive(:cpu_count).and_return(nil)

        result = check.run

        expect(result.warnings).to include(match(/Could not determine CPU usage/))
        expect(result.warnings).to include(match(/Could not determine CPU count/))
      end
    end

    context "when only 1 CPU core is available" do
      it "adds a warning about low core count" do
        check = build_check
        allow(check).to receive(:current_cpu_usage).and_return(30.0)
        allow(check).to receive(:cpu_count).and_return(1)

        result = check.run

        expect(result.warnings).to include(match(/Only 1 CPU core/))
      end
    end

    context "with custom thresholds" do
      it "respects custom warning threshold" do
        check = build_check(warning_threshold: 50.0, critical_threshold: 70.0)
        allow(check).to receive(:current_cpu_usage).and_return(55.0)
        allow(check).to receive(:cpu_count).and_return(2)

        result = check.run

        expect(result.warnings).to include(match(/CPU usage is elevated: 55.0%.*50.0%/))
      end

      it "respects custom critical threshold" do
        check = build_check(warning_threshold: 50.0, critical_threshold: 70.0)
        allow(check).to receive(:current_cpu_usage).and_return(75.0)
        allow(check).to receive(:cpu_count).and_return(2)

        result = check.run

        expect(result.errors).to include(match(/CPU usage is critically high: 75.0%.*70.0%/))
      end
    end
  end
end
