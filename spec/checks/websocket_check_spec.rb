# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/websocket_check"
require "rails_deploy_check/checks/websocket_check_integration"

RSpec.describe RailsDeployCheck::Checks::WebsocketCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when cable.yml does not exist" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("cable.yml") }).to be true
        end
      end
    end

    context "when cable.yml exists with redis adapter" do
      it "adds an info message about redis adapter" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "cable.yml"),
            "production:\n  adapter: redis\n  url: redis://localhost:6379\n"
          )
          result = build_check(app_path: app_path).run
          expect(result.infos.any? { |i| i.include?("Redis") }).to be true
          expect(result.errors).to be_empty
        end
      end
    end

    context "when cable.yml uses async adapter" do
      it "adds a warning about async adapter" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "cable.yml"),
            "production:\n  adapter: async\n"
          )
          result = build_check(app_path: app_path).run
          expect(result.warnings.any? { |w| w.include?("async") }).to be true
        end
      end
    end

    context "when WEBSOCKET_URL uses insecure ws:// scheme" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path, ws_url: "ws://example.com/cable").run
          expect(result.warnings.any? { |w| w.include?("insecure") }).to be true
        end
      end
    end

    context "when WEBSOCKET_URL uses secure wss:// scheme" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path, ws_url: "wss://example.com/cable").run
          expect(result.infos.any? { |i| i.include?("wss") }).to be true
          expect(result.errors).to be_empty
        end
      end
    end

    context "when WEBSOCKET_URL is invalid" do
      it "adds an error" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path, ws_url: "not a url !!!").run
          expect(result.errors.any? { |e| e.include?("not a valid URI") || e.include?("unsupported scheme") }).to be true
        end
      end
    end
  end

  describe RailsDeployCheck::Checks::WebsocketCheckIntegration do
    describe ".applicable?" do
      it "returns true when cable.yml exists" do
        with_tmp_rails_app do |app_path|
          FileUtils.mkdir_p(File.join(app_path, "config"))
          File.write(File.join(app_path, "config", "cable.yml"), "")
          expect(described_class.applicable?(app_path: app_path)).to be true
        end
      end

      it "returns false when no indicators are present" do
        with_tmp_rails_app do |app_path|
          ClimateControl.modify("WEBSOCKET_URL" => nil, "ACTION_CABLE_URL" => nil) do
            expect(described_class.applicable?(app_path: app_path)).to be false
          end
        end
      end
    end
  end
end
