# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/gzip_check"

RSpec.describe RailsDeployCheck::Checks::GzipCheck do
  def build_check(options = {})
    described_class.new({ app_path: @tmpdir }.merge(options))
  end

  def create_file(relative_path, content = "")
    full_path = File.join(@tmpdir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      example.run
    end
  end

  describe "#run" do
    context "when nginx config exists with gzip enabled" do
      it "adds an info message" do
        create_file("config/nginx.conf", "gzip on;\ngzip_types text/plain;")
        result = build_check(check_assets: false).run
        expect(result.infos.any? { |i| i.include?("gzip compression is enabled") }).to be true
      end
    end

    context "when nginx config exists without gzip" do
      it "adds a warning" do
        create_file("config/nginx.conf", "server { listen 80; }")
        result = build_check(check_assets: false).run
        expect(result.warnings.any? { |w| w.include?("gzip is not enabled") }).to be true
      end
    end

    context "when no nginx config is found" do
      it "adds an info message about skipping" do
        result = build_check(check_nginx: true, check_assets: false).run
        expect(result.infos.any? { |i| i.include?("skipping nginx gzip check") }).to be true
      end
    end

    context "when pre-compressed assets exist" do
      it "reports the count of .gz files" do
        create_file("public/assets/application-abc123.js.gz", "")
        create_file("public/assets/application-abc123.css.gz", "")
        result = build_check(check_nginx: false).run
        expect(result.infos.any? { |i| i.include?("2 pre-compressed") }).to be true
      end
    end

    context "when assets directory exists but no .gz files" do
      it "warns about missing compressed assets" do
        FileUtils.mkdir_p(File.join(@tmpdir, "public", "assets"))
        result = build_check(check_nginx: false).run
        expect(result.warnings.any? { |w| w.include?("No pre-compressed") }).to be true
      end
    end

    context "when assets directory does not exist" do
      it "warns to run assets:precompile" do
        result = build_check(check_nginx: false, check_assets: true).run
        expect(result.warnings.any? { |w| w.include?("assets:precompile") }).to be true
      end
    end

    context "when Rack::Deflater is configured in production.rb" do
      it "adds an info message" do
        create_file("config/environments/production.rb",
          "config.middleware.use Rack::Deflater")
        result = build_check(check_nginx: false, check_assets: false).run
        expect(result.infos.any? { |i| i.include?("Rack::Deflater") }).to be true
      end
    end

    context "when Rack::Deflater is not configured" do
      it "warns to add Rack::Deflater" do
        result = build_check(check_nginx: false, check_assets: false).run
        expect(result.warnings.any? { |w| w.include?("Rack::Deflater not configured") }).to be true
      end
    end
  end
end
