# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/connection_timeout_check"

RSpec.describe RailsDeployCheck::Checks::ConnectionTimeoutCheck do
  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  around do |example|
    with_tmp_rails_app do |app_path|
      @app_path = app_path
      example.run
    end
  end

  describe "#run" do
    context "when database.yml does not exist" do
      it "returns an info message" do
        check = build_check(app_path: @app_path)
        result = check.run
        expect(result.infos).to include(a_string_matching(/database.yml not found/))
      end
    end

    context "when database.yml has no timeouts configured" do
      before do
        create_file(
          File.join(@app_path, "config", "database.yml"),
          "production:\n  adapter: postgresql\n  pool: 5\n"
        )
      end

      it "warns about missing connect_timeout" do
        result = build_check(app_path: @app_path).run
        expect(result.warnings).to include(a_string_matching(/connect_timeout/))
      end

      it "warns about missing checkout_timeout" do
        result = build_check(app_path: @app_path).run
        expect(result.warnings).to include(a_string_matching(/checkout_timeout/))
      end
    end

    context "when connect_timeout is within acceptable range" do
      before do
        create_file(
          File.join(@app_path, "config", "database.yml"),
          "production:\n  adapter: postgresql\n  connect_timeout: 5\n  checkout_timeout: 10\n"
        )
      end

      it "reports info for acceptable connect_timeout" do
        result = build_check(app_path: @app_path).run
        expect(result.infos).to include(a_string_matching(/connect_timeout is set to 5s/))
      end
    end

    context "when connect_timeout exceeds warning threshold" do
      before do
        create_file(
          File.join(@app_path, "config", "database.yml"),
          "production:\n  adapter: postgresql\n  connect_timeout: 45\n"
        )
      end

      it "adds a warning" do
        result = build_check(app_path: @app_path, warn_threshold: 30).run
        expect(result.warnings).to include(a_string_matching(/exceeds warning threshold/))
      end
    end

    context "when connect_timeout exceeds error threshold" do
      before do
        create_file(
          File.join(@app_path, "config", "database.yml"),
          "production:\n  adapter: postgresql\n  connect_timeout: 150\n"
        )
      end

      it "adds an error" do
        result = build_check(app_path: @app_path, error_threshold: 120).run
        expect(result.errors).to include(a_string_matching(/exceeds error threshold/))
      end
    end

    context "when DATABASE_CONNECT_TIMEOUT env var is set" do
      before do
        create_file(
          File.join(@app_path, "config", "database.yml"),
          "production:\n  adapter: postgresql\n  connect_timeout: 5\n"
        )
      end

      it "warns when env timeout exceeds warning threshold" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("DATABASE_CONNECT_TIMEOUT").and_return("60")
        allow(ENV).to receive(:[]).with("DB_CONNECT_TIMEOUT").and_return(nil)

        result = build_check(app_path: @app_path, warn_threshold: 30).run
        expect(result.warnings).to include(a_string_matching(/DATABASE_CONNECT_TIMEOUT env is 60s/))
      end
    end
  end
end
