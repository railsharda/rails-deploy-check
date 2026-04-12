# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/locale_check"

RSpec.describe RailsDeployCheck::Checks::LocaleCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when config/locales directory does not exist" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("config/locales") }).to be true
        end
      end
    end

    context "when config/locales directory exists" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          FileUtils.mkdir_p(File.join(app_path, "config", "locales"))
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("config/locales") }).to be true
        end
      end
    end

    context "when en.yml exists" do
      it "adds an info message about the default locale" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "locales", "en.yml"), "en:\n  hello: Hello")
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("en.yml") }).to be true
        end
      end
    end

    context "when required locales are configured" do
      it "reports missing locale files as errors" do
        with_tmp_rails_app do |app_path|
          FileUtils.mkdir_p(File.join(app_path, "config", "locales"))
          create_file(File.join(app_path, "config", "locales", "en.yml"), "en:\n  hello: Hello")
          result = build_check(app_path: app_path, required_locales: ["en", "fr", "de"]).run
          expect(result.errors.any? { |e| e.include?("fr.yml") }).to be true
          expect(result.errors.any? { |e| e.include?("de.yml") }).to be true
        end
      end

      it "adds info when all required locales are present" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "locales", "en.yml"), "en:\n  hello: Hello")
          create_file(File.join(app_path, "config", "locales", "fr.yml"), "fr:\n  hello: Bonjour")
          result = build_check(app_path: app_path, required_locales: ["en", "fr"]).run
          expect(result.errors).to be_empty
          expect(result.infos.any? { |i| i.include?("en") && i.include?("fr") }).to be true
        end
      end
    end

    context "when missing_translations.yml exists" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "locales", "missing_translations.yml"), "")
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("missing_translations") }).to be true
        end
      end
    end

    context "when no missing_translations.yml" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          FileUtils.mkdir_p(File.join(app_path, "config", "locales"))
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("missing_translations") }).to be true
        end
      end
    end
  end
end
