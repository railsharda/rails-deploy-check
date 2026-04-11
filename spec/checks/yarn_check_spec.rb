# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/yarn_check"
require "rails_deploy_check/checks/yarn_check_integration"

RSpec.describe RailsDeployCheck::Checks::YarnCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(app_path)
    described_class.new(app_path: app_path)
  end

  describe "#run" do
    context "when yarn.lock and package.json exist" do
      it "adds info messages for both files" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "yarn.lock"))
          create_file(File.join(app_path, "package.json"), '{"dependencies":{}}')

          result = build_check(app_pathrun

          messages = result.messages.map(&:text)
          expect(messages).to include("yarn.lock found")
          expect(messages).to include("package.json found")
        end
      end
    end

    context "when yarn.lock is missing" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path).run

          warnings = result.messages.select { |m| m.level == :warning }.map(&:text)
          expect(warnings).to include(a_string_matching(/yarn.lock not found/))
        end
      end
    end

    context "when package.json is newer than yarn.lock" do
      it "warns that dependencies may be out of sync" do
        with_tmp_rails_app do |app_path|
          lock_path = File.join(app_path, "yarn.lock")
          pkg_path  = File.join(app_path, "package.json")

          create_file(lock_path)
          sleep(0.05)
          create_file(pkg_path, '{"dependencies":{}}')

          result = build_check(app_path).run

          warnings = result.messages.select { |m| m.level == :warning }.map(&:text)
          expect(warnings).to include(a_string_matching(/out of sync/))
        end
      end
    end

    context "when yarn.lock is newer than package.json" do
      it "adds an info message that lock is up to date" do
        with_tmp_rails_app do |app_path|
          pkg_path  = File.join(app_path, "package.json")
          lock_path = File.join(app_path, "yarn.lock")

          create_file(pkg_path, '{"dependencies":{}}')
          sleep(0.05)
          create_file(lock_path)

          result = build_check(app_path).run

          infos = result.messages.select { |m| m.level == :info }.map(&:text)
          expect(infos).to include(a_string_matching(/up to date/))
        end
      end
    end
  end

  describe RailsDeployCheck::Checks::YarnCheckIntegration do
    describe ".applicable?" do
      it "returns true when yarn.lock exists" do
        with_tmp_rails_app do |app_path|
          File.write(File.join(app_path, "yarn.lock"), "")
          expect(described_class.applicable?(app_path)).to be true
        end
      end

      it "returns false when neither file exists" do
        with_tmp_rails_app do |app_path|
          expect(described_class.applicable?(app_path)).to be false
        end
      end
    end
  end
end
