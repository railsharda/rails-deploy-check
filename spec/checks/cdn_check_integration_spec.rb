require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::CdnCheckIntegration do
  describe ".applicable?" do
    context "when CDN_URL env var is set" do
      it "returns true" do
        with_env("CDN_URL" => "https://cdn.example.com") do
          expect(described_class.applicable?).to be true
        end
      end
    end

    context "when ASSET_HOST env var is set" do
      it "returns true" do
        with_env("ASSET_HOST" => "https://assets.example.com") do
          expect(described_class.applicable?).to be true
        end
      end
    end

    context "when neither env var is set and no config file" do
      it "returns false" do
        with_env("CDN_URL" => nil, "ASSET_HOST" => nil) do
          allow(described_class).to receive(:asset_host_in_production_config?).and_return(false)
          expect(described_class.applicable?).to be false
        end
      end
    end

    context "when asset_host is in production config" do
      it "returns true" do
        with_env("CDN_URL" => nil, "ASSET_HOST" => nil) do
          allow(described_class).to receive(:asset_host_in_production_config?).and_return(true)
          expect(described_class.applicable?).to be true
        end
      end
    end
  end

  describe ".build" do
    it "returns a CdnCheck instance" do
      check = described_class.build
      expect(check).to be_a(RailsDeployCheck::Checks::CdnCheck)
    end
  end

  def with_env(vars)
    old = vars.keys.each_with_object({}) { |k, h| h[k] = ENV[k] }
    vars.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k.to_s) : ENV[k.to_s] = v }
  end
end
