# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::GraphqlCheckIntegration do
  describe ".applicable?" do
    context "when graphql gem is in Gemfile.lock" do
      it "returns true" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?)
          .with(File.join(Dir.pwd, "Gemfile.lock"))
          .and_return(true)
        allow(File).to receive(:read)
          .with(File.join(Dir.pwd, "Gemfile.lock"))
          .and_return("    graphql (2.1.4)\n")

        expect(described_class.applicable?).to be true
      end
    end

    context "when graphql_controller.rb exists" do
      it "returns true" do
        allow(described_class).to receive(:graphql_in_lockfile?).and_return(false)
        allow(File).to receive(:exist?)
          .with(File.join(Dir.pwd, "app", "controllers", "graphql_controller.rb"))
          .and_return(true)

        expect(described_class.applicable?).to be true
      end
    end

    context "when neither condition is met" do
      it "returns false" do
        allow(described_class).to receive(:graphql_in_lockfile?).and_return(false)
        allow(described_class).to receive(:graphql_controller_present?).and_return(false)

        expect(described_class.applicable?).to be false
      end
    end
  end

  describe ".build" do
    it "returns a GraphqlCheck instance" do
      check = described_class.build(app_path: Dir.pwd)
      expect(check).to be_a(RailsDeployCheck::Checks::GraphqlCheck)
    end
  end

  describe ".register" do
    it "registers the check when applicable" do
      registry = {}
      allow(described_class).to receive(:applicable?).and_return(true)
      allow(registry).to receive(:register)

      described_class.register(registry)

      expect(registry).to have_received(:register).with(:graphql, anything)
    end

    it "does not register when not applicable" do
      registry = {}
      allow(described_class).to receive(:applicable?).and_return(false)
      allow(registry).to receive(:register)

      described_class.register(registry)

      expect(registry).not_to have_received(:register)
    end
  end
end
