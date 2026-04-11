require "spec_helper"
require "rails_deploy_check/checks/permissions_check"

RSpec.describe RailsDeployCheck::Checks::PermissionsCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe "#run" do
    context "writable directories" do
      it "reports info when writable directories exist and are writable" do
        with_tmp_rails_app do |app_path|
          dir = File.join(app_path, "tmp")
          FileUtils.mkdir_p(dir)
          FileUtils.chmod(0o755, dir)

          check = build_check(app_path: app_path, writable_dirs: ["tmp"])
          result = check.run

          expect(result.infos).to include(a_string_matching(/writable/))
          expect(result.errors).to be_empty
        end
      end

      it "reports an error when a required directory is not writable" do
        with_tmp_rails_app do |app_path|
          dir = File.join(app_path, "tmp")
          FileUtils.mkdir_p(dir)
          FileUtils.chmod(0o444, dir)

          check = build_check(app_path: app_path, writable_dirs: ["tmp"])
          result = check.run

          expect(result.errors).to include(a_string_matching(/not writable.*tmp/))
        ensure
          FileUtils.chmod(0o755, dir)
        end
      end

      it "skips directories that do not exist" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, writable_dirs: ["nonexistent_dir"])
          result = check.run

          expect(result.errors).to be_empty
          expect(result.warnings).to be_empty
        end
      end
    end

    context "readable files" do
      it "reports info when readable files are readable" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "database.yml"), "adapter: sqlite3")

          check = build_check(app_path: app_path, readable_files: ["config/database.yml"])
          result = check.run

          expect(result.infos).to include(a_string_matching(/readable.*database\.yml/))
        end
      end

      it "skips files that do not exist" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, readable_files: ["config/missing.yml"])
          result = check.run

          expect(result.errors).to be_empty
        end
      end
    end

    context "binstub executability" do
      it "reports info when all binstubs are executable" do
        with_tmp_rails_app do |app_path|
          bin = File.join(app_path, "bin")
          FileUtils.mkdir_p(bin)
          stub = File.join(bin, "rails")
          File.write(stub, "#!/usr/bin/env ruby")
          FileUtils.chmod(0o755, stub)

          check = build_check(app_path: app_path, writable_dirs: [], readable_files: [])
          result = check.run

          expect(result.infos).to include(a_string_matching(/binstubs.*executable/))
        end
      end

      it "warns when bin/ directory is missing" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, writable_dirs: [], readable_files: [])
          result = check.run

          expect(result.warnings).to include(a_string_matching(/bin\/.*not found/))
        end
      end
    end
  end
end
