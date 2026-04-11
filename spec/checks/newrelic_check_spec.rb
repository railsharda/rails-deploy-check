# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::NewrelicCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(tmp_dir, **opts)
    described_class.new(app_root: tmp_dir, **opts)
  end

  context "when newrelic_rpm is not in Gemfile.lock" do
    it "adds an info message and skips further checks" do
      with_tmp_rails_app do |tmp|
        create_file("#{tmp}/Gemfile.lock", "GEM\n  specs:\n    rails (7.0.0)\n")
        check = build_check(tmp, license_key: "abc")
        result = check.run
        expect(result.infos).to include(match(/skipping New Relic checks/))
        expect(result.errors).to be_empty
      end
    end
  end

  context "when newrelic_rpm is in Gemfile.lock" do
    let(:lockfile_content) do
      "GEM\n  specs:\n    newrelic_rpm (9.0.0)\n    rails (7.0.0)\n"
    end

    it "reports an error when license key is missing" do
      with_tmp_rails_app do |tmp|
        create_file("#{tmp}/Gemfile.lock", lockfile_content)
        check = build_check(tmp, license_key: nil, app_name: "MyApp")
        result = check.run
        expect(result.errors).to include(match(/NEW_RELIC_LICENSE_KEY is not set/))
      end
    end

    it "reports an error when license key is blank" do
      with_tmp_rails_app do |tmp|
        create_file("#{tmp}/Gemfile.lock", lockfile_content)
        check = build_check(tmp, license_key: "   ", app_name: "MyApp")
        result = check.run
        expect(result.errors).to include(match(/NEW_RELIC_LICENSE_KEY is not set/))
      end
    end

    it "reports a warning when license key is too short" do
      with_tmp_rails_app do |tmp|
        create_file("#{tmp}/Gemfile.lock", lockfile_content)
        check = build_check(tmp, license_key: "shortkey123", app_name: "MyApp")
        result = check.run
        expect(result.warnings).to include(match(/appears too short/))
      end
    end

    it "reports info when license key is valid" do
      with_tmp_rails_app do |tmp|
        create_file("#{tmp}/Gemfile.lock", lockfile_content)
        check = build_check(tmp, license_key: "a" * 40, app_name: "MyApp")
        result = check.run
        expect(result.infos).to include(match(/NEW_RELIC_LICENSE_KEY is present/))
        expect(result.errors).to be_empty
      end
    end

    it "warns when app name is not set" do
      with_tmp_rails_app do |tmp|
        create_file("#{tmp}/Gemfile.lock", lockfile_content)
        check = build_check(tmp, license_key: "a" * 40, app_name: nil)
        result = check.run
        expect(result.warnings).to include(match(/NEW_RELIC_APP_NAME is not set/))
      end
    end

    it "reports info when newrelic.yml config exists" do
      with_tmp_rails_app do |tmp|
        create_file("#{tmp}/Gemfile.lock", lockfile_content)
        create_file("#{tmp}/config/newrelic.yml", "common:\n  license_key: test\n")
        check = build_check(tmp, license_key: "a" * 40, app_name: "MyApp")
        result = check.run
        expect(result.infos).to include(match(/config\/newrelic.yml/))
      end
    end

    it "warns when newrelic.yml config is missing" do
      with_tmp_rails_app do |tmp|
        create_file("#{tmp}/Gemfile.lock", lockfile_content)
        check = build_check(tmp, license_key: "a" * 40, app_name: "MyApp")
        result = check.run
        expect(result.warnings).to include(match(/config\/newrelic.yml not found/))
      end
    end
  end
end
