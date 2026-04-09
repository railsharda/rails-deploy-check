# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/bundler_audit_check"

RSpec.describe RailsDeployCheck::Checks::BundlerAuditCheck do
  let(:app_path) { Dir.mktmpdir }

  after { FileUtils.rm_rf(app_path) }

  def create_file(relative_path, content = "")
    full_path = File.join(app_path, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def build_check(options = {})
    described_class.new({ app_path: app_path }.merge(options))
  end

  describe "#run" do
    context "when bundler-audit is not installed" do
      before do
        allow_any_instance_of(described_class).to receive(:bundler_audit_available?).and_return(false)
      end

      it "returns a warning and skips the check" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/bundler-audit gem is not installed/))
        expect(result.errors).to be_empty
      end
    end

    context "when bundler-audit is available" do
      before do
        allow_any_instance_of(described_class).to receive(:bundler_audit_available?).and_return(true)
      end

      context "when Gemfile.lock does not exist" do
        it "adds an error about missing lockfile" do
          result = build_check.run
          expect(result.errors).to include(a_string_matching(/Gemfile.lock not found/))
        end
      end

      context "when Gemfile.lock exists" do
        before { create_file("Gemfile.lock", "GEM\n  specs:\n") }

        context "when no vulnerabilities are found" do
          before do
            allow_any_instance_of(described_class).to receive(:run_audit_command).and_return(["No vulnerabilities found", 0])
          end

          it "reports no vulnerabilities" do
            result = build_check.run
            expect(result.info).to include(a_string_matching(/No known vulnerabilities/))
            expect(result.errors).to be_empty
            expect(result.warnings).to be_empty
          end
        end

        context "when vulnerabilities are found" do
          let(:audit_output) { "Name: activesupport\nVersion: 5.0.0\nAdvisory: CVE-2021-1234\n" }

          before do
            allow_any_instance_of(described_class).to receive(:run_audit_command).and_return([audit_output, 1])
          end

          it "adds a warning by default" do
            result = build_check.run
            expect(result.warnings).to include(a_string_matching(/vulnerable gem/))
            expect(result.errors).to be_empty
          end

          it "adds an error when fail_on_warnings is true" do
            result = build_check(fail_on_warnings: true).run
            expect(result.errors).to include(a_string_matching(/vulnerable gem/))
            expect(result.warnings).to be_empty
          end
        end

        context "when audit exits with unexpected status" do
          before do
            allow_any_instance_of(described_class).to receive(:run_audit_command).and_return(["", 2])
          end

          it "adds a warning about unexpected exit status" do
            result = build_check.run
            expect(result.warnings).to include(a_string_matching(/unexpected status/))
          end
        end
      end
    end
  end
end
