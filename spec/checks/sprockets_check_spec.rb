# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/sprockets_check"

RSpec.describe RailsDeployCheck::Checks::SprocketsCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe "#run" do
    context "when Gemfile.lock is missing" do
      it "adds a warning about missing lockfile" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("Gemfile.lock") }).to be true
        end
      end
    end

    context "when Gemfile.lock exists without sprockets" do
      it "adds an info message that sprockets is not detected" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "GEM\n  specs:\n    rails (7.0.0)\n")
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("not detected") }).to be true
        end
      end
    end

    context "when Gemfile.lock includes sprockets" do
      it "adds an info message confirming sprockets is present" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "GEM\n  specs:\n    sprockets (4.1.1)\n")
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("sprockets gem is present") }).to be true
        end
      end
    end

    context "when public/assets directory is missing" do
      it "adds a warning about missing precompiled assets" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "GEM\n  specs:\n    sprockets (4.1.1)\n")
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("public/assets") }).to be true
        end
      end
    end

    context "when public/assets exists but has no manifest" do
      it "adds an error about missing manifest" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "GEM\n  specs:\n    sprockets (4.1.1)\n")
          FileUtils.mkdir_p(File.join(app_path, "public", "assets"))
          result = build_check(app_path: app_path).run
          expect(result.errors.any? { |e| e.include?("No Sprockets manifest") }).to be true
        end
      end
    end

    context "when a valid sprockets manifest is present" do
      it "adds an info message with the file count" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "GEM\n  specs:\n    sprockets (4.1.1)\n")
          manifest_path = File.join(app_path, "public", "assets", ".sprockets-manifest-abc123.json")
          create_file(manifest_path, JSON.dump({ "files" => { "application-abc.js" => {}, "application-def.css" => {} } }))
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("2 compiled asset") }).to be true
        end
      end
    end

    context "when sass source files are present in public/assets" do
      it "adds a warning about uncompiled stylesheets" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "GEM\n  specs:\n    sprockets (4.1.1)\n")
          manifest_path = File.join(app_path, "public", "assets", ".sprockets-manifest-abc123.json")
          create_file(manifest_path, JSON.dump({ "files" => { "app.js" => {} } }))
          create_file(File.join(app_path, "public", "assets", "application.scss"), "body { color: red; }")
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("application.scss") }).to be true
        end
      end
    end

    context "when check_digest is false" do
      it "skips manifest digest check" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "Gemfile.lock"), "GEM\n  specs:\n    sprockets (4.1.1)\n")
          manifest_path = File.join(app_path, "public", "assets", ".sprockets-manifest-abc123.json")
          create_file(manifest_path, "NOT JSON")
          result = build_check(app_path: app_path, check_digest: false).run
          expect(result.warnings.none? { |w| w.include?("parsed as JSON") }).to be true
        end
      end
    end
  end
end
