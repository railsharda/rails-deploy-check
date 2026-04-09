require "spec_helper"
require "rails_deploy_check/checks/gemfile_check"

RSpec.describe RailsDeployCheck::Checks::GemfileCheck do
  let(:tmpdir) { Dir.mktmpdir }
  let(:check)  { described_class.new(app_path: tmpdir) }

  def create_file(name, content = "")
    path = File.join(tmpdir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  after { FileUtils.rm_rf(tmpdir) }

  describe "#run" do
    context "when Gemfile and Gemfile.lock are missing" do
      it "reports errors for both missing files" do
        result = check.run
        expect(result.errors.length).to eq(2)
        expect(result.errors).to include(a_string_matching(/Gemfile not found/))
        expect(result.errors).to include(a_string_matching(/Gemfile.lock not found/))
      end
    end

    context "when Gemfile exists but Gemfile.lock is missing" do
      before { create_file("Gemfile", 'source "https://rubygems.org"') }

      it "reports an error for missing Gemfile.lock" do
        result = check.run
        expect(result.errors).to include(a_string_matching(/Gemfile.lock not found/))
        expect(result.errors.none? { |e| e.match?(/Gemfile not found/) }).to be true
      end
    end

    context "when both files exist and are in sync" do
      before do
        create_file("Gemfile", 'source "https://rubygems.org"')
        sleep(0.01)
        create_file("Gemfile.lock", "GEM\n  remote: https://rubygems.org/\n\nGROUPS\n  production\n")
      end

      it "passes without errors or warnings" do
        result = check.run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
      end
    end

    context "when Gemfile is newer than Gemfile.lock" do
      before do
        create_file("Gemfile.lock", "GEM\n  remote: https://rubygems.org/\n\nGROUPS\n  production\n")
        sleep(0.01)
        create_file("Gemfile", 'source "https://rubygems.org"')
      end

      it "adds a warning about stale lockfile" do
        result = check.run
        expect(result.warnings).to include(a_string_matching(/newer than Gemfile.lock/))
      end
    end

    context "when a required bundle group is missing from Gemfile.lock" do
      before do
        create_file("Gemfile", 'source "https://rubygems.org"')
        sleep(0.01)
        create_file("Gemfile.lock", "GEM\n  remote: https://rubygems.org/\n")
      end

      it "warns about the missing group" do
        result = check.run
        expect(result.warnings).to include(a_string_matching(/production/))
      end
    end

    context "with custom warn_missing_groups option" do
      let(:check) { described_class.new(app_path: tmpdir, warn_missing_groups: ["staging"]) }

      before do
        create_file("Gemfile", 'source "https://rubygems.org"')
        sleep(0.01)
        create_file("Gemfile.lock", "GEM\n  remote: https://rubygems.org/\n")
      end

      it "warns about the custom group" do
        result = check.run
        expect(result.warnings).to include(a_string_matching(/staging/))
      end
    end
  end
end
