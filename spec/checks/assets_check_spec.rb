require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::AssetsCheck do
  let(:tmp_dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(tmp_dir) }

  def create_file(path, content = "")
    full_path = File.join(tmp_dir, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  subject(:check) { described_class.new(app_root: tmp_dir) }

  describe "#run" do
    context "when no assets are precompiled" do
      it "adds an error for missing manifest" do
        result = check.run
        expect(result.errors).to include(a_string_matching(/No asset manifest found/))
      end

      it "adds a warning for missing public/assets directory" do
        result = check.run
        expect(result.warnings).to include(a_string_matching(/public\/assets directory does not exist/))
      end
    end

    context "when manifest exists" do
      before do
        create_file("public/assets/.sprockets-manifest-abc123.json", '{"files":{}}')
      end

      it "does not error about missing manifest" do
        result = check.run
        expect(result.errors).not_to include(a_string_matching(/No asset manifest found/))
      end

      it "adds an info message about the manifest" do
        result = check.run
        expect(result.infos).to include(a_string_matching(/Asset manifest found/))
      end
    end

    context "when compiled assets are present" do
      before do
        create_file("public/assets/.sprockets-manifest-abc.json", "{}")
        create_file("public/assets/application-abc123.css", "body {}")
        create_file("public/assets/application-def456.js", "console.log('hi')")
      end

      it "reports compiled assets as present" do
        result = check.run
        infos = result.infos.join(" ")
        expect(infos).to include("application.css")
        expect(infos).to include("application.js")
      end
    end

    context "when asset_host check is enabled" do
      it "warns when asset_host is not configured" do
        check = described_class.new(app_root: tmp_dir, check_asset_host: true, asset_host: nil)
        result = check.run
        expect(result.warnings).to include(a_string_matching(/ASSET_HOST is not configured/))
      end

      it "adds info when asset_host is configured" do
        check = described_class.new(app_root: tmp_dir, check_asset_host: true, asset_host: "https://cdn.example.com")
        result = check.run
        expect(result.infos).to include(a_string_matching(/Asset host configured/))
      end
    end
  end
end
