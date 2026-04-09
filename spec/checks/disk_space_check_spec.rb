require "spec_helper"
require "shellwords"

RSpec.describe RailsDeployCheck::Checks::DiskSpaceCheck do
  let(:app_root) { Dir.mktmpdir }

  after { FileUtils.remove_entry(app_root) }

  def build_check(config = {})
    described_class.new({ app_root: app_root }.merge(config))
  end

  describe "#run" do
    context "when all paths have sufficient disk space" do
      it "returns a passing result with info messages" do
        check = build_check(paths: ["/"])
        allow(check).to receive(:available_mb).and_return(2048)

        result = check.run

        expect(result).to be_success
        expect(result.infos).not_to be_empty
      end
    end

    context "when a path has low disk space" do
      it "adds an error to the result" do
        check = build_check(paths: ["/"], min_free_mb: 1000)
        allow(check).to receive(:available_mb).and_return(200)

        result = check.run

        expect(result).not_to be_success
        expect(result.errors.first).to match(/Low disk space/)
        expect(result.errors.first).to match(/200MB free/)
      end
    end

    context "when a relative path does not exist" do
      it "adds a warning for the missing path" do
        check = build_check(paths: ["nonexistent_dir"])

        result = check.run

        expect(result).to be_success
        expect(result.warnings.first).to match(/does not exist/)
      end
    end

    context "when a relative path exists" do
      it "resolves relative paths from app_root" do
        FileUtils.mkdir_p(File.join(app_root, "tmp"))
        check = build_check(paths: ["tmp"])
        allow(check).to receive(:available_mb).and_return(1000)

        result = check.run

        expect(result).to be_success
      end
    end

    context "when df command fails" do
      it "adds a warning instead of raising" do
        check = build_check(paths: ["/"])
        allow(check).to receive(:available_mb).and_return(nil)

        result = check.run

        expect(result).to be_success
        expect(result.warnings.first).to match(/Could not determine disk space/)
      end
    end

    context "with custom min_free_mb" do
      it "uses the configured threshold" do
        check = build_check(paths: ["/"], min_free_mb: 100)
        allow(check).to receive(:available_mb).and_return(150)

        result = check.run

        expect(result).to be_success
        expect(result.infos.first).to match(/150MB free/)
      end
    end
  end
end
