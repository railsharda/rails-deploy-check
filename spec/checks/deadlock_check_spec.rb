# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/deadlock_check"

RSpec.describe RailsDeployCheck::Checks::DeadlockCheck do
  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  context "when database.yml does not exist" do
    it "adds a warning" do
      with_tmp_rails_app do |app_path|
        check = build_check(app_path: app_path)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("database.yml not found") }).to be true
      end
    end
  end

  context "when database.yml exists without timeout settings" do
    it "warns about missing lock_timeout" do
      with_tmp_rails_app do |app_path|
        create_file(
          File.join(app_path, "config", "database.yml"),
          "default: &default\n  adapter: postgresql\n  pool: 5\n"
        )
        check = build_check(app_path: app_path)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("lock_timeout") }).to be true
      end
    end

    it "warns about missing statement_timeout" do
      with_tmp_rails_app do |app_path|
        create_file(
          File.join(app_path, "config", "database.yml"),
          "default: &default\n  adapter: postgresql\n  pool: 5\n"
        )
        check = build_check(app_path: app_path)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("statement_timeout") }).to be true
      end
    end
  end

  context "when database.yml has both timeout settings" do
    it "adds info messages for lock_timeout and statement_timeout" do
      with_tmp_rails_app do |app_path|
        create_file(
          File.join(app_path, "config", "database.yml"),
          "default: &default\n  adapter: postgresql\n  pool: 5\n  lock_timeout: 5000\n  statement_timeout: 30000\n"
        )
        check = build_check(app_path: app_path)
        result = check.run
        expect(result.infos.any? { |i| i.include?("lock_timeout") }).to be true
        expect(result.infos.any? { |i| i.include?("statement_timeout") }).to be true
        expect(result.warnings).to be_empty
        expect(result.errors).to be_empty
      end
    end
  end

  context "when database.yml has only lock_timeout" do
    it "warns about missing statement_timeout only" do
      with_tmp_rails_app do |app_path|
        create_file(
          File.join(app_path, "config", "database.yml"),
          "default: &default\n  adapter: postgresql\n  lock_timeout: 5000\n"
        )
        check = build_check(app_path: app_path)
        result = check.run
        expect(result.warnings.any? { |w| w.include?("statement_timeout") }).to be true
        expect(result.warnings.none? { |w| w.include?("lock_timeout") }).to be true
      end
    end
  end
end
