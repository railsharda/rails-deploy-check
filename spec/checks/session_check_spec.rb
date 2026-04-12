# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/session_check"

RSpec.describe RailsDeployCheck::Checks::SessionCheck do
  def build_check(app_path:, env: {})
    described_class.new(app_path: app_path, env: env)
  end

  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe "#run" do
    context "SECRET_KEY_BASE" do
      it "adds an error when SECRET_KEY_BASE is missing" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path, env: {}).run
          expect(result.errors).to include(a_string_matching(/SECRET_KEY_BASE.*not set/i))
        end
      end

      it "adds an error when SECRET_KEY_BASE is blank" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path, env: { "SECRET_KEY_BASE" => "  " }).run
          expect(result.errors).to include(a_string_matching(/SECRET_KEY_BASE.*not set/i))
        end
      end

      it "adds a warning when SECRET_KEY_BASE is too short" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path, env: { "SECRET_KEY_BASE" => "tooshort" }).run
          expect(result.warnings).to include(a_string_matching(/too short/i))
        end
      end

      it "adds info when SECRET_KEY_BASE is sufficiently long" do
        with_tmp_rails_app do |app_path|
          long_key = "a" * 64
          result = build_check(app_path: app_path, env: { "SECRET_KEY_BASE" => long_key }).run
          expect(result.infos).to include(a_string_matching(/SECRET_KEY_BASE is present/i))
        end
      end
    end

    context "session store configuration" do
      it "adds info when session_store initializer contains a known store" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "initializers", "session_store.rb"),
            "Rails.application.config.session_store :cookie_store, key: '_app_session'"
          )
          result = build_check(app_path: app_path, env: { "SECRET_KEY_BASE" => "a" * 64 }).run
          expect(result.infos).to include(a_string_matching(/cookie_store/i))
        end
      end

      it "adds a warning when session_store.rb has no recognized store" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "initializers", "session_store.rb"),
            "# empty"
          )
          result = build_check(app_path: app_path, env: { "SECRET_KEY_BASE" => "a" * 64 }).run
          expect(result.warnings).to include(a_string_matching(/no recognized session store/i))
        end
      end

      it "adds a warning when no session store config is found" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path, env: { "SECRET_KEY_BASE" => "a" * 64 }).run
          expect(result.warnings).to include(a_string_matching(/No explicit session store/i))
        end
      end
    end

    context "cookie store secret rotation" do
      it "adds info when rotation is configured" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "initializers", "session_store.rb"),
            "Rails.application.config.session_store :cookie_store\nRotate secret_key_base_older"
          )
          result = build_check(app_path: app_path, env: { "SECRET_KEY_BASE" => "a" * 64 }).run
          expect(result.infos).to include(a_string_matching(/rotation.*configured/i))
        end
      end

      it "adds a warning when cookie store has no rotation" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "initializers", "session_store.rb"),
            "Rails.application.config.session_store :cookie_store, key: '_app'"
          )
          result = build_check(app_path: app_path, env: { "SECRET_KEY_BASE" => "a" * 64 }).run
          expect(result.warnings).to include(a_string_matching(/secret rotation/i))
        end
      end
    end
  end
end
