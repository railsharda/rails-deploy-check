require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::RubyVersionCheck do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:check) { described_class.new(app_path: tmp_dir) }

  def create_file(name, content)
    File.write(File.join(tmp_dir, name), content)
  end

  after { FileUtils.rm_rf(tmp_dir) }

  describe "#run" do
    context "when .ruby-version and Gemfile are present with matching versions" do
      before do
        create_file(".ruby-version", "3.2.2\n")
        create_file("Gemfile", "source 'https://rubygems.org'\nruby '3.2.2'\ngem 'rails'\n")
      end

      it "returns a passing result" do
        result = check.run
        expect(result).to be_passed
      end

      it "reports version consistency info" do
        result = check.run
        expect(result.infos).to include(match(/consistent/))
      end
    end

    context "when .ruby-version and Gemfile have mismatched versions" do
      before do
        create_file(".ruby-version", "3.1.0\n")
        create_file("Gemfile", "source 'https://rubygems.org'\nruby '3.2.2'\n")
      end

      it "returns a failing result" do
        result = check.run
        expect(result).not_to be_passed
      end

      it "reports a version mismatch error" do
        result = check.run
        expect(result.errors).to include(match(/mismatch/))
      end
    end

    context "when .ruby-version file is missing" do
      before do
        create_file("Gemfile", "source 'https://rubygems.org'\nruby '3.2.2'\n")
      end

      it "adds a warning" do
        result = check.run
        expect(result.warnings).to include(match(/\.ruby-version/))
      end
    end

    context "when Gemfile is missing" do
      before do
        create_file(".ruby-version", "3.2.2\n")
      end

      it "adds an error" do
        result = check.run
        expect(result.errors).to include(match(/Gemfile not found/))
      end
    end

    context "when Gemfile has no ruby directive" do
      before do
        create_file(".ruby-version", "3.2.2\n")
        create_file("Gemfile", "source 'https://rubygems.org'\ngem 'rails'\n")
      end

      it "adds a warning about missing ruby directive" do
        result = check.run
        expect(result.warnings).to include(match(/ruby version directive/))
      end
    end
  end
end
