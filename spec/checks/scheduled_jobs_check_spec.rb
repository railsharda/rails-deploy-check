# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/scheduled_jobs_check"

RSpec.describe RailsDeployCheck::Checks::ScheduledJobsCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  around do |example|
    with_tmp_rails_app { example.run }
  end

  describe "#run" do
    context "when neither whenever gem nor schedule.rb is present" do
      it "adds a warning" do
        check = build_check(app_path: Dir.pwd)
        result = check.run
        expect(result.warnings).to include(match(/No scheduled job configuration found/))
      end
    end

    context "when whenever gem is in Gemfile.lock" do
      before do
        create_file("Gemfile.lock", "    whenever (1.0.0)\n")
      end

      it "adds an info message" do
        check = build_check(app_path: Dir.pwd)
        result = check.run
        expect(result.infos).to include(match(/whenever gem detected/))
      end
    end

    context "when schedule.rb exists and is empty" do
      before do
        create_file("config/schedule.rb", "")
      end

      it "adds a warning about empty schedule file" do
        check = build_check(app_path: Dir.pwd)
        result = check.run
        expect(result.warnings).to include(match(/exists but is empty/))
      end
    end

    context "when schedule.rb contains valid job definitions" do
      before do
        create_file("config/schedule.rb", <<~RUBY)
          every 1.day, at: '4:30 am' do
            rake 'cleanup:old_records'
          end
        RUBY
      end

      it "adds an info message about job definitions" do
        check = build_check(app_path: Dir.pwd)
        result = check.run
        expect(result.infos).to include(match(/contains job definitions/))
      end
    end

    context "when expected_jobs are specified" do
      before do
        create_file("config/schedule.rb", <<~RUBY)
          every 1.day do
            rake 'cleanup:old_records'
          end
        RUBY
      end

      it "adds an error when an expected job is missing" do
        check = build_check(app_path: Dir.pwd, expected_jobs: ["cleanup:old_records", "reports:generate"])
        result = check.run
        expect(result.errors).to include(match(/reports:generate/))
      end

      it "adds info when all expected jobs are present" do
        check = build_check(app_path: Dir.pwd, expected_jobs: ["cleanup:old_records"])
        result = check.run
        expect(result.infos).to include(match(/All expected scheduled jobs are present/))
      end
    end
  end
end
