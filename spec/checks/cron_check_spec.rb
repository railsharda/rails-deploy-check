require "spec_helper"
require "rails_deploy_check/checks/cron_check"

RSpec.describe RailsDeployCheck::Checks::CronCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(app_path:, **opts)
    described_class.new(app_path: app_path, **opts)
  end

  context "when schedule file exists" do
    it "adds an info message for a non-empty schedule file" do
      with_tmp_rails_app do |app_path|
        create_file(File.join(app_path, "config/schedule.rb"), "every 1.day do\n  runner 'MyJob.run'\nend\n")
        result = build_check(app_path: app_path).run
        expect(result.infos).to include(a_string_matching(/Schedule file found/))
        expect(result.warnings).to be_empty
      end
    end

    it "warns when schedule file is empty" do
      with_tmp_rails_app do |app_path|
        create_file(File.join(app_path, "config/schedule.rb"), "")
        result = build_check(app_path: app_path).run
        expect(result.warnings).to include(a_string_matching(/empty/))
      end
    end
  end

  context "when no schedule file exists" do
    it "adds a warning" do
      with_tmp_rails_app do |app_path|
        result = build_check(app_path: app_path).run
        expect(result.warnings).to include(a_string_matching(/No schedule file found/))
      end
    end
  end

  context "Gemfile.lock detection" do
    it "detects a known cron gem" do
      with_tmp_rails_app do |app_path|
        lockfile_content = "GEM\n  specs:\n    whenever (1.0.0)\n"
        create_file(File.join(app_path, "Gemfile.lock"), lockfile_content)
        result = build_check(app_path: app_path).run
        expect(result.infos).to include(a_string_matching(/whenever/))
      end
    end

    it "reports no cron gem when none present" do
      with_tmp_rails_app do |app_path|
        create_file(File.join(app_path, "Gemfile.lock"), "GEM\n  specs:\n    rails (7.0.0)\n")
        result = build_check(app_path: app_path).run
        expect(result.infos).to include(a_string_matching(/No known cron gem detected/))
      end
    end

    it "warns when Gemfile.lock is missing" do
      with_tmp_rails_app do |app_path|
        result = build_check(app_path: app_path).run
        expect(result.warnings).to include(a_string_matching(/Gemfile.lock not found/))
      end
    end

    it "skips gem check when check_gem is false" do
      with_tmp_rails_app do |app_path|
        result = build_check(app_path: app_path, check_gem: false).run
        expect(result.warnings.none? { |w| w.include?("Gemfile.lock") }).to be true
      end
    end
  end

  context "with custom schedule_paths" do
    it "finds a file at a custom path" do
      with_tmp_rails_app do |app_path|
        create_file(File.join(app_path, "config/my_schedule.rb"), "# custom schedule\n")
        result = build_check(
          app_path: app_path,
          schedule_paths: ["config/my_schedule.rb"],
          check_gem: false
        ).run
        expect(result.infos).to include(a_string_matching(/my_schedule\.rb/))
      end
    end
  end
end
