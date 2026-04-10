# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::StorageCheckIntegration do
  around do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  describe ".active_storage_present?" do
    context "when config/storage.yml exists" do
      it "returns true" do
        FileUtils.mkdir_p(File.join(@tmpdir, "config"))
        File.write(File.join(@tmpdir, "config", "storage.yml"), "")
        expect(described_class.active_storage_present?(@tmpdir)).to be true
      end
    end

    context "when Gemfile.lock contains activestorage" do
      it "returns true" do
        File.write(File.join(@tmpdir, "Gemfile.lock"), "    activestorage (7.0.4)\n")
        expect(described_class.active_storage_present?(@tmpdir)).to be true
      end
    end

    context "when neither storage.yml nor activestorage in lockfile" do
      it "returns false" do
        File.write(File.join(@tmpdir, "Gemfile.lock"), "    rails (7.0.4)\n")
        expect(described_class.active_storage_present?(@tmpdir)).to be false
      end
    end
  end

  describe ".build" do
    context "when Active Storage is present" do
      it "returns a StorageCheck instance" do
        FileUtils.mkdir_p(File.join(@tmpdir, "config"))
        File.write(File.join(@tmpdir, "config", "storage.yml"), "")
        check = described_class.build(app_path: @tmpdir)
        expect(check).to be_a(RailsDeployCheck::Checks::StorageCheck)
      end
    end

    context "when Active Storage is not present" do
      it "returns nil" do
        check = described_class.build(app_path: @tmpdir)
        expect(check).to be_nil
      end
    end
  end

  describe ".register" do
    it "appends the check to config.checks when applicable" do
      FileUtils.mkdir_p(File.join(@tmpdir, "config"))
      File.write(File.join(@tmpdir, "config", "storage.yml"), "")

      config = double("config", checks: [])
      described_class.register(config, app_path: @tmpdir)
      expect(config.checks.length).to eq(1)
      expect(config.checks.first).to be_a(RailsDeployCheck::Checks::StorageCheck)
    end

    it "does not append when Active Storage is not present" do
      config = double("config", checks: [])
      described_class.register(config, app_path: @tmpdir)
      expect(config.checks).to be_empty
    end
  end
end
