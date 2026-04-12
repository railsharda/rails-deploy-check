# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/file_watchers_check"

RSpec.describe RailsDeployCheck::Checks::FileWatchersCheck do
  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(app_path)
    described_class.new(app_path: app_path)
  end

  it "reports no warnings when lockfile has no watcher gems" do
    with_tmp_rails_app do |app_path|
      create_file("#{app_path}/Gemfile.lock", "GEM\n  specs:\n    rails (7.0.0)\n")
      result = build_check(app_path).run
      expect(result.warnings).to be_empty
      expect(result.errors).to be_empty
    end
  end

  it "warns when watcher gems are found in the lockfile" do
    with_tmp_rails_app do |app_path|
      create_file("#{app_path}/Gemfile.lock", "GEM\n  specs:\n    listen (3.8.0)\n    spring (4.1.0)\n")
      result = build_check(app_path).run
      expect(result.warnings.first).to include("listen", "spring")
    end
  end

  it "warns when Spring PID files exist" do
    with_tmp_rails_app do |app_path|
      create_file("#{app_path}/Gemfile.lock", "GEM\n  specs:\n")
      pid_dir = "#{app_path}/tmp/spring"
      FileUtils.mkdir_p(pid_dir)
      File.write("#{pid_dir}/12345.pid", "12345")

      result = build_check(app_path).run
      expect(result.warnings.any? { |w| w.include?("Spring") }).to be true
    end
  end

  it "does not warn when Spring PID directory is absent" do
    with_tmp_rails_app do |app_path|
      create_file("#{app_path}/Gemfile.lock", "GEM\n  specs:\n")
      result = build_check(app_path).run
      spring_warnings = result.warnings.select { |w| w.include?("Spring") }
      expect(spring_warnings).to be_empty
    end
  end

  it "reports an error when listen gem is outside dev/test group in Gemfile" do
    with_tmp_rails_app do |app_path|
      create_file("#{app_path}/Gemfile.lock", "GEM\n  specs:\n")
      create_file("#{app_path}/Gemfile", "source 'https://rubygems.org'\ngem 'rails'\ngem 'listen'\n")
      result = build_check(app_path).run
      expect(result.errors.any? { |e| e.include?("listen") }).to be true
    end
  end

  it "does not error when listen is inside a development group" do
    with_tmp_rails_app do |app_path|
      create_file("#{app_path}/Gemfile.lock", "GEM\n  specs:\n")
      gemfile_content = <<~GEMFILE
        source 'https://rubygems.org'
        gem 'rails'
        group :development, :test do
          gem 'listen'
        end
      GEMFILE
      create_file("#{app_path}/Gemfile", gemfile_content)
      result = build_check(app_path).run
      listen_errors = result.errors.select { |e| e.include?("listen") }
      expect(listen_errors).to be_empty
    end
  end

  it "handles missing Gemfile.lock gracefully" do
    with_tmp_rails_app do |app_path|
      result = build_check(app_path).run
      expect(result.errors).to be_empty
    end
  end
end
