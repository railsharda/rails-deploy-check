# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::RackTimeoutCheck do
  def create_file(path, content = "")
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
    context "when rack-timeout gem is in Gemfile.lock" do
      before do
        create_file(File.join(@app_path, "Gemfile.lock"), "    rack-timeout (0.6.3)\n")
      end

      it "adds info about gem presence" do
        result = build_check(app_path: @app_path).run
        expect(result.infos).to include(a_string_matching(/rack-timeout gem found/))
      end
    end

    context "when rack-timeout gem is not in Gemfile.lock" do
      before do
        create_file(File.join(@app_path, "Gemfile.lock"), "    rails (7.0.0)\n")
      end

      it "adds a warning about missing gem" do
        result = build_check(app_path: @app_path).run
        expect(result.warnings).to include(a_string_matching(/rack-timeout gem not found/))
      end
    end

    context "when timeout initializer exists" do
      before do
        create_file(File.join(@app_path, "Gemfile.lock"), "    rack-timeout (0.6.3)\n")
        create_file(File.join(@app_path, "config", "initializers", "rack_timeout.rb"), "Rack::Timeout.service_timeout = 15")
      end

      it "adds info about initializer" do
        result = build_check(app_path: @app_path).run
        expect(result.infos).to include(a_string_matching(/initializer found/))
      end
    end

    context "when no initializer exists" do
      before do
        create_file(File.join(@app_path, "Gemfile.lock"), "    rack-timeout (0.6.3)\n")
      end

      it "adds a warning about missing initializer" do
        result = build_check(app_path: @app_path).run
        expect(result.warnings).to include(a_string_matching(/No rack-timeout initializer found/))
      end
    end

    context "with RACK_TIMEOUT_SERVICE_TIMEOUT set" do
      before do
        create_file(File.join(@app_path, "Gemfile.lock"), "    rack-timeout (0.6.3)\n")
      end

      it "adds info when timeout is valid" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:key?).and_call_original
        allow(ENV).to receive(:[]).with("RACK_TIMEOUT_SERVICE_TIMEOUT").and_return("15")
        allow(ENV).to receive(:[]).with("RACK_TIMEOUT_WAIT_TIMEOUT").and_return(nil)
        result = build_check(app_path: @app_path).run
        expect(result.infos).to include(a_string_matching(/RACK_TIMEOUT_SERVICE_TIMEOUT is set to 15s/))
      end

      it "adds error when timeout is zero" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("RACK_TIMEOUT_SERVICE_TIMEOUT").and_return("0")
        allow(ENV).to receive(:[]).with("RACK_TIMEOUT_WAIT_TIMEOUT").and_return(nil)
        result = build_check(app_path: @app_path).run
        expect(result.errors).to include(a_string_matching(/invalid value/))
      end
    end
  end
end
