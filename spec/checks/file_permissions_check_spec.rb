# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/file_permissions_check"

RSpec.describe RailsDeployCheck::Checks::FilePermissionsCheck do
  def build_check(app_path:)
    described_class.new(app_path: app_path, result: RailsDeployCheck::Result.new)
  end

  def create_file(path, content: "", mode: 0o640)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    File.chmod(mode, path)
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  describe "#run" do
    context "when sensitive file is world-writable" do
      it "adds an error" do
        create_file(File.join(@tmpdir, "config/database.yml"), mode: 0o666)
        result = build_check(app_path: @tmpdir).run
        expect(result.errors).to include(a_string_matching(/world-writable/))
      end
    end

    context "when sensitive file is world-readable but not world-writable" do
      it "adds a warning" do
        create_file(File.join(@tmpdir, "config/master.key"), mode: 0o644)
        result = build_check(app_path: @tmpdir).run
        expect(result.warnings).to include(a_string_matching(/world-readable/))
      end
    end

    context "when sensitive file has safe permissions" do
      it "adds an info message" do
        create_file(File.join(@tmpdir, "config/master.key"), mode: 0o600)
        result = build_check(app_path: @tmpdir).run
        expect(result.info).to include(a_string_matching(/safe permissions/))
      end
    end

    context "when sensitive file does not exist" do
      it "does not add any messages for that file" do
        result = build_check(app_path: @tmpdir).run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
      end
    end

    context "when writable directory exists" do
      it "adds an info message" do
        FileUtils.mkdir_p(File.join(@tmpdir, "tmp"))
        result = build_check(app_path: @tmpdir).run
        expect(result.info).to include(a_string_matching(/tmp\/ is writable/))
      end
    end

    context "when required directory is not writable" do
      it "adds an error" do
        dir_path = File.join(@tmpdir, "log")
        FileUtils.mkdir_p(dir_path)
        FileUtils.chmod(0o444, dir_path)
        result = build_check(app_path: @tmpdir).run
        expect(result.errors).to include(a_string_matching(/log\/ is not writable/))
        FileUtils.chmod(0o755, dir_path)
      end
    end
  end
end
