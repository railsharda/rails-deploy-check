require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::LogCheck do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:log_dir) { File.join(tmp_dir, "log") }

  after { FileUtils.rm_rf(tmp_dir) }

  def build_check(options = {})
    described_class.new({ app_path: tmp_dir, log_dir: log_dir, rails_env: "production" }.merge(options))
  end

  describe "#run" do
    context "when log directory does not exist" do
      it "returns a warning" do
        result = build_check.run
        expect(result.warnings.any? { |w| w.include?("not found") }).to be true
      end

      it "does not return an error for missing directory" do
        result = build_check.run
        expect(result.errors.none? { |e| e.include?("not found") }).to be true
      end
    end

    context "when log directory exists" do
      before { FileUtils.mkdir_p(log_dir) }

      it "reports the log directory as present" do
        result = build_check.run
        expect(result.info.any? { |i| i.include?("exists") }).to be true
      end

      context "when log file is within acceptable size" do
        before do
          File.write(File.join(log_dir, "production.log"), "log entry\n" * 100)
        end

        it "reports acceptable size" do
          result = build_check.run
          expect(result.info.any? { |i| i.include?("acceptable") }).to be true
        end
      end

      context "when log file exceeds warning threshold" do
        before do
          check = build_check(size_warning_mb: 0)
          File.write(File.join(log_dir, "production.log"), "x" * 1024)
          @check = check
        end

        it "adds a warning about log file size" do
          result = @check.run
          expect(result.warnings.any? { |w| w.include?("large") }).to be true
        end
      end

      context "when log file exceeds error threshold" do
        before do
          File.write(File.join(log_dir, "production.log"), "x" * 1024)
        end

        it "adds an error about log file size" do
          result = build_check(size_error_mb: 0).run
          expect(result.errors.any? { |e| e.include?("very large") }).to be true
        end
      end

      context "when log directory is not writable" do
        before { FileUtils.chmod(0o555, log_dir) }
        after  { FileUtils.chmod(0o755, log_dir) }

        it "adds an error about writability" do
          result = build_check.run
          expect(result.errors.any? { |e| e.include?("not writable") }).to be true
        end
      end
    end
  end

  describe "default options" do
    it "uses RAILS_ENV when set" do
      allow(ENV).to receive(:[]).with("RAILS_ENV").and_return("staging")
      check = described_class.new(app_path: tmp_dir)
      expect(check.instance_variable_get(:@rails_env)).to eq("staging")
    end

    it "falls back to production when RAILS_ENV is not set" do
      allow(ENV).to receive(:[]).with("RAILS_ENV").and_return(nil)
      check = described_class.new(app_path: tmp_dir)
      expect(check.instance_variable_get(:@rails_env)).to eq("production")
    end
  end
end
