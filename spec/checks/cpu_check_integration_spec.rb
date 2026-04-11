require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::CpuCheckIntegration do
  describe ".build" do
    it "returns a CpuCheck instance" do
      check = described_class.build
      expect(check).to be_a(RailsDeployCheck::Checks::CpuCheck)
    end

    it "passes options to the check" do
      check = described_class.build(warning_threshold: 60.0, critical_threshold: 85.0)
      expect(check.instance_variable_get(:@warning_threshold)).to eq(60.0)
      expect(check.instance_variable_get(:@critical_threshold)).to eq(85.0)
    end
  end

  describe ".applicable?" do
    context "on Linux" do
      it "returns true" do
        stub_const("RUBY_PLATFORM", "x86_64-linux")
        expect(described_class.applicable?).to be true
      end
    end

    context "on macOS" do
      it "returns true" do
        stub_const("RUBY_PLATFORM", "arm64-darwin23")
        expect(described_class.applicable?).to be true
      end
    end

    context "on Windows" do
      it "returns false" do
        stub_const("RUBY_PLATFORM", "x64-mingw-ucrt")
        expect(described_class.applicable?).to be false
      end
    end
  end

  describe ".detected_platform" do
    it "returns :linux on Linux" do
      stub_const("RUBY_PLATFORM", "x86_64-linux")
      expect(described_class.detected_platform).to eq(:linux)
    end

    it "returns :macos on macOS" do
      stub_const("RUBY_PLATFORM", "arm64-darwin23")
      expect(described_class.detected_platform).to eq(:macos)
    end

    it "returns :unknown on unsupported platforms" do
      stub_const("RUBY_PLATFORM", "x64-mingw-ucrt")
      expect(described_class.detected_platform).to eq(:unknown)
    end
  end

  describe ".register" do
    it "registers the check on applicable platforms" do
      allow(described_class).to receive(:applicable?).and_return(true)
      runner = double("runner")
      expect(runner).to receive(:register).with(:cpu, an_instance_of(RailsDeployCheck::Checks::CpuCheck))
      described_class.register(runner)
    end

    it "does not register on non-applicable platforms" do
      allow(described_class).to receive(:applicable?).and_return(false)
      runner = double("runner")
      expect(runner).not_to receive(:register)
      described_class.register(runner)
    end
  end
end
