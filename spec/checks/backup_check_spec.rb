require "spec_helper"
require "rails_deploy_check/checks/backup_check"
require "rails_deploy_check/checks/backup_check_integration"

RSpec.describe RailsDeployCheck::Checks::BackupCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(app_path:, **opts)
    described_class.new(app_path: app_path, **opts)
  end

  describe "#run" do
    context "when backup config exists" do
      it "reports info for a found config file" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/config/backup.rb", "# backup config")

          check = build_check(app_path: app_path, require_config: true)
          result = check.run

          expect(result.infos).to include(match(/Backup configuration file found/))
          expect(result.errors).to be_empty
        end
      end
    end

    context "when backup config is missing and required" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, require_config: true)
          result = check.run

          expect(result.warnings).to include(match(/No backup configuration file found/))
        end
      end
    end

    context "when require_config is false" do
      it "skips the config check" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, require_config: false)
          result = check.run

          expect(result.infos).to include(match(/skipped/))
        end
      end
    end

    context "when a backup directory exists" do
      it "reports info and checks writability" do
        with_tmp_rails_app do |app_path|
          dir = "#{app_path}/tmp/backups"
          FileUtils.mkdir_p(dir)

          check = build_check(app_path: app_path, require_config: false)
          result = check.run

          expect(result.infos).to include(match(/Backup directory found/))
          expect(result.infos).to include(match(/writable/))
        end
      end
    end

    context "when no backup directory exists" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          check = build_check(app_path: app_path, require_config: false)
          result = check.run

          expect(result.warnings).to include(match(/No backup directory found/))
        end
      end
    end
  end

  describe RailsDeployCheck::Checks::BackupCheckIntegration do
    describe ".applicable?" do
      it "returns false when no backup indicators are present" do
        with_tmp_rails_app do |app_path|
          expect(described_class.applicable?(app_path)).to be false
        end
      end

      it "returns true when a backup directory is present" do
        with_tmp_rails_app do |app_path|
          FileUtils.mkdir_p("#{app_path}/backups")
          expect(described_class.applicable?(app_path)).to be true
        end
      end
    end
  end
end
