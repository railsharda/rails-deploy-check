# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::DatabasePoolCheckIntegration do
  describe ".applicable?" do
    it "returns true when database.yml exists" do
      with_tmp_rails_app do |app_path|
        FileUtils.mkdir_p(File.join(app_path, "config"))
        File.write(File.join(app_path, "config", "database.yml"), "adapter: postgresql\n")
        allow(Dir).to receive(:pwd).and_return(app_path)
        expect(described_class.applicable?).to be true
      end
    end

    it "returns true when Gemfile.lock contains activerecord" do
      with_tmp_rails_app do |app_path|
        File.write(File.join(app_path, "Gemfile.lock"), "    activerecord (7.1.0)\n")
        allow(Dir).to receive(:pwd).and_return(app_path)
        expect(described_class.applicable?).to be true
      end
    end

    it "returns false when neither database.yml nor activerecord are present" do
      with_tmp_rails_app do |app_path|
        allow(Dir).to receive(:pwd).and_return(app_path)
        expect(described_class.applicable?).to be false
      end
    end
  end

  describe ".build" do
    it "returns a DatabasePoolCheck instance" do
      with_tmp_rails_app do |app_path|
        check = described_class.build(app_path: app_path)
        expect(check).to be_a(RailsDeployCheck::Checks::DatabasePoolCheck)
      end
    end

    it "passes custom pool size options" do
      with_tmp_rails_app do |app_path|
        check = described_class.build(app_path: app_path, min_pool_size: 3, max_pool_size: 50)
        expect(check.instance_variable_get(:@min_pool_size)).to eq(3)
        expect(check.instance_variable_get(:@max_pool_size)).to eq(50)
      end
    end
  end

  describe ".register" do
    it "registers the check when applicable" do
      registry = double("registry")
      allow(described_class).to receive(:applicable?).and_return(true)
      expect(registry).to receive(:register).with(:database_pool, anything)
      described_class.register(registry)
    end

    it "does not register when not applicable" do
      registry = double("registry")
      allow(described_class).to receive(:applicable?).and_return(false)
      expect(registry).not_to receive(:register)
      described_class.register(registry)
    end
  end
end
