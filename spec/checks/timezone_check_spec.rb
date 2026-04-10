require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::TimezoneCheck do
  let(:tmp_dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(tmp_dir) }

  def create_file(relative_path, content)
    full_path = File.join(tmp_dir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def build_check(options = {})
    described_class.new({ app_path: tmp_dir }.merge(options))
  end

  describe "#run" do
    context "when TZ is set to UTC" do
      around do |example|
        old_tz = ENV["TZ"]
        ENV["TZ"] = "UTC"
        example.run
        ENV["TZ"] = old_tz
      end

      it "adds an info message for TZ variable" do
        result = build_check.run
        expect(result.infos.any? { |i| i.include?("UTC") }).to be true
      end
    end

    context "when TZ is not set" do
      around do |example|
        old_tz = ENV.delete("TZ")
        example.run
        ENV["TZ"] = old_tz if old_tz
      end

      it "adds a warning about missing TZ" do
        result = build_check.run
        expect(result.warnings.any? { |w| w.include?("TZ environment variable") }).to be true
      end
    end

    context "when require_utc is true and TZ is not UTC" do
      around do |example|
        old_tz = ENV["TZ"]
        ENV["TZ"] = "America/New_York"
        example.run
        ENV["TZ"] = old_tz
      end

      it "adds an error" do
        result = build_check(require_utc: true).run
        expect(result.errors.any? { |e| e.include?("UTC is required") }).to be true
      end
    end

    context "when config/application.rb sets time_zone" do
      before do
        create_file("config/application.rb", "config.time_zone = \"UTC\"\n")
      end

      it "reports the configured timezone" do
        result = build_check.run
        expect(result.infos.any? { |i| i.include?("UTC") }).to be true
      end
    end

    context "when config/application.rb does not set time_zone" do
      before do
        create_file("config/application.rb", "# no timezone config\n")
      end

      it "adds a warning" do
        result = build_check.run
        expect(result.warnings.any? { |w| w.include?("time_zone") }).to be true
      end
    end

    context "when require_utc is true and config sets non-UTC timezone" do
      before do
        create_file("config/application.rb", "config.time_zone = \"Tokyo\"\n")
      end

      it "adds an error for non-UTC time_zone" do
        result = build_check(require_utc: true).run
        expect(result.errors.any? { |e| e.include?("UTC is required") }).to be true
      end
    end

    context "when config/database.yml has timezone variable" do
      before do
        create_file("config/application.rb", "config.time_zone = \"UTC\"\n")
        create_file("config/database.yml", "variables:\n  time_zone: \"UTC\"\n")
      end

      it "reports database timezone info" do
        result = build_check.run
        expect(result.infos.any? { |i| i.include?("Database timezone") }).to be true
      end
    end
  end
end
