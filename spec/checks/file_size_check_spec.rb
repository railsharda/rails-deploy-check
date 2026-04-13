# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::FileSizeCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, size_bytes = 0)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "wb") { |f| f.write("x" * size_bytes) }
  end

  describe "#run" do
    context "when no paths are configured" do
      it "returns an info message" do
        check = build_check(paths: [])
        result = check.run
        expect(result.infos).to include(match(/No paths configured/))
        expect(result.errors).to be_empty
      end
    end

    context "when a path does not exist" do
      it "adds an info message and skips the check" do
        with_tmp_rails_app do |root|
          check = build_check(root: root, paths: [{ path: "nonexistent", max_mb: 100, label: "Missing dir" }])
          result = check.run
          expect(result.infos).to include(match(/does not exist/))
          expect(result.errors).to be_empty
        end
      end
    end

    context "when a directory is within the size limit" do
      it "adds an info message" do
        with_tmp_rails_app do |root|
          log_dir = File.join(root, "log")
          FileUtils.mkdir_p(log_dir)
          create_file(File.join(log_dir, "production.log"), 1024)

          check = build_check(root: root, paths: [{ path: "log", max_mb: 500, label: "Log directory" }])
          result = check.run
          expect(result.errors).to be_empty
          expect(result.warnings).to be_empty
          expect(result.infos).to include(match(/Log directory size is/))
        end
      end
    end

    context "when a directory is near the size limit (>= 80%)" do
      it "adds a warning" do
        with_tmp_rails_app do |root|
          log_dir = File.join(root, "log")
          FileUtils.mkdir_p(log_dir)
          # Simulate ~85% of 1MB limit => 0.85 MB
          create_file(File.join(log_dir, "production.log"), (0.85 * 1_048_576).to_i)

          check = build_check(root: root, paths: [{ path: "log", max_mb: 1, label: "Log directory" }])
          result = check.run
          expect(result.warnings).to include(match(/approaching/))
          expect(result.errors).to be_empty
        end
      end
    end

    context "when a directory exceeds the size limit" do
      it "adds an error" do
        with_tmp_rails_app do |root|
          log_dir = File.join(root, "log")
          FileUtils.mkdir_p(log_dir)
          create_file(File.join(log_dir, "production.log"), (2 * 1_048_576).to_i)

          check = build_check(root: root, paths: [{ path: "log", max_mb: 1, label: "Log directory" }])
          result = check.run
          expect(result.errors).to include(match(/exceeds 1MB limit/))
        end
      end
    end
  end
end
