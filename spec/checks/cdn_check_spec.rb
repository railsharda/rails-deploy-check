require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::CdnCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe "#run" do
    context "when CDN_URL is not set" do
      it "adds a warning" do
        check = build_check(cdn_url: nil)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/No CDN URL configured/))
      end
    end

    context "when CDN_URL is set to a valid URL" do
      it "adds an info message" do
        check = build_check(cdn_url: "https://cdn.example.com")
        result = check.run
        expect(result.infos).to include(a_string_matching(/CDN URL configured/))
        expect(result.errors).to be_empty
      end
    end

    context "when CDN_URL has an invalid format" do
      it "adds an error" do
        check = build_check(cdn_url: "cdn.example.com")
        result = check.run
        expect(result.errors).to include(a_string_matching(/does not start with http/))
      end
    end

    context "when CDN_URL has a trailing slash" do
      it "adds a warning" do
        check = build_check(cdn_url: "https://cdn.example.com/")
        result = check.run
        expect(result.warnings).to include(a_string_matching(/trailing slash/))
      end
    end

    context "when asset_host is present in production config" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "environments", "production.rb"),
            "config.asset_host = ENV['CDN_URL']\n"
          )
          check = build_check(app_path: app_path, cdn_url: "https://cdn.example.com")
          result = check.run
          expect(result.infos).to include(a_string_matching(/asset_host is referenced/))
        end
      end
    end

    context "when asset_host is absent from config files" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          create_file(
            File.join(app_path, "config", "environments", "production.rb"),
            "# no asset_host here\n"
          )
          check = build_check(app_path: app_path, cdn_url: "https://cdn.example.com")
          result = check.run
          expect(result.warnings).to include(a_string_matching(/No asset_host setting/))
        end
      end
    end
  end
end
