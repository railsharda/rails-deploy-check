# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::RackTimeoutCheckIntegration do
  around do |example|
    with_tmp_rails_app do |app_path|
      @app_path = app_path
      example.run
    end
  end

  describe ".applicable?" do
    context "when rack-timeout is in Gemfile.lock" do
      before do
        FileUtils.mkdir_p(@app_path)
        File.write(File.join(@app_path, "Gemfile.lock"), "    rack-timeout (0.6.3)\n")
      end

      it "returns true" do
        expect(described_class.applicable?(app_path: @app_path)).to be true
      end
    end

    context "when RACK_TIMEOUT_SERVICE_TIMEOUT env var is set" do
      before do
        File.write(File.join(@app_path, "Gemfile.lock"), "    rails (7.0.0)\n")
        allow(ENV).to receive(:key?).and_call_original
        allow(ENV).to receive(:key?).with("RACK_TIMEOUT_SERVICE_TIMEOUT").and_return(true)
        allow(ENV).to receive(:key?).with("RACK_TIMEOUT_WAIT_TIMEOUT").and_return(false)
      end

      it "returns true" do
        expect(described_class.applicable?(app_path: @app_path)).to be true
      end
    end

    context "when neither gem nor env var is present" do
      before do
        File.write(File.join(@app_path, "Gemfile.lock"), "    rails (7.0.0)\n")
        allow(ENV).to receive(:key?).and_call_original
        allow(ENV).to receive(:key?).with("RACK_TIMEOUT_SERVICE_TIMEOUT").and_return(false)
        allow(ENV).to receive(:key?).with("RACK_TIMEOUT_WAIT_TIMEOUT").and_return(false)
      end

      it "returns false" do
        expect(described_class.applicable?(app_path: @app_path)).to be false
      end
    end
  end

  describe ".build" do
    it "returns a RackTimeoutCheck instance" do
      check = described_class.build(app_path: @app_path)
      expect(check).to be_a(RailsDeployCheck::Checks::RackTimeoutCheck)
    end
  end

  describe ".register" do
    it "appends check to registry when applicable" do
      File.write(File.join(@app_path, "Gemfile.lock"), "    rack-timeout (0.6.3)\n")
      registry = []
      described_class.register(registry, app_path: @app_path)
      expect(registry.length).to eq(1)
      expect(registry.first).to be_a(RailsDeployCheck::Checks::RackTimeoutCheck)
    end

    it "does not append check when not applicable" do
      File.write(File.join(@app_path, "Gemfile.lock"), "    rails (7.0.0)\n")
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with("RACK_TIMEOUT_SERVICE_TIMEOUT").and_return(false)
      allow(ENV).to receive(:key?).with("RACK_TIMEOUT_WAIT_TIMEOUT").and_return(false)
      registry = []
      described_class.register(registry, app_path: @app_path)
      expect(registry).to be_empty
    end
  end
end
