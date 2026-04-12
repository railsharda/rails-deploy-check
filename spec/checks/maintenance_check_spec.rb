# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/maintenance_check"

RSpec.describe RailsDeployCheck::Checks::MaintenanceCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @tmp = dir
      example.run
    end
  end

  describe "#run" do
    context "when no maintenance file exists and MAINTENANCE_MODE is not set" do
      it "returns no errors" do
        check = build_check(app_path: @tmp, check_public_dir: false)
        result = check.run
        expect(result.errors).to be_empty
      end

      it "adds an info message about the missing lock file" do
        check = build_check(app_path: @tmp, check_public_dir: false)
        result = check.run
        expect(result.infos.any? { |i| i.include?("No maintenance lock file") }).to be true
      end
    end

    context "when tmp/maintenance.txt exists" do
      it "adds an error" do
        create_file(File.join(@tmp, "tmp", "maintenance.txt"))
        check = build_check(app_path: @tmp, check_public_dir: false)
        result = check.run
        expect(result.errors.any? { |e| e.include?("Maintenance mode is active") }).to be true
      end
    end

    context "when a custom maintenance file path is given and it exists" do
      it "adds an error for the custom path" do
        custom = File.join(@tmp, "MAINTENANCE")
        create_file(custom)
        check = build_check(app_path: @tmp, maintenance_file: custom, check_public_dir: false)
        result = check.run
        expect(result.errors.any? { |e| e.include?("Maintenance mode is active") }).to be true
      end
    end

    context "when MAINTENANCE_MODE=true" do
      around do |example|
        ENV["MAINTENANCE_MODE"] = "true"
        example.run
      ensure
        ENV.delete("MAINTENANCE_MODE")
      end

      it "adds an error" do
        check = build_check(app_path: @tmp, check_public_dir: false)
        result = check.run
        expect(result.errors.any? { |e| e.include?("MAINTENANCE_MODE") }).to be true
      end
    end

    context "when check_public_dir is true" do
      it "adds a warning when public/maintenance.html is missing" do
        check = build_check(app_path: @tmp, check_public_dir: true)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("maintenance.html") }).to be true
      end

      it "adds an info when public/maintenance.html exists" do
        create_file(File.join(@tmp, "public", "maintenance.html"), "<h1>Down for maintenance</h1>")
        check = build_check(app_path: @tmp, check_public_dir: true)
        result = check.run
        expect(result.warnings.none? { |w| w.include?("maintenance.html") }).to be true
        expect(result.infos.any? { |i| i.include?("maintenance.html") }).to be true
      end
    end
  end
end
