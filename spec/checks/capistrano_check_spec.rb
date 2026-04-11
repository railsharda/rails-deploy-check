# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/capistrano_check"

RSpec.describe RailsDeployCheck::Checks::CapistranoCheck do
  def create_file(path, content = "")
    full_path = File.join(@root, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def build_check(config = {})
    described_class.new({ root: @root }.merge(config))
  end

  around do |example|
    with_tmp_rails_app { |dir| @root = dir; example.run }
  end

  describe "#run" do
    context "when Capfile and config/deploy.rb are present" do
      before do
        create_file("Capfile", "# Capfile")
        create_file("config/deploy.rb", "# deploy config")
      end

      it "reports info for Capfile found" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Capfile found/))
      end

      it "reports info for config/deploy.rb found" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/config\/deploy\.rb found/))
      end
    end

    context "when Capfile is missing" do
      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/Capfile not found/))
      end
    end

    context "when config/deploy.rb is missing" do
      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/config\/deploy\.rb not found/))
      end
    end

    context "when Gemfile.lock contains capistrano gems" do
      before do
        create_file("Gemfile.lock", "    capistrano (3.17.0)\n    capistrano-rails (1.6.2)\n")
      end

      it "reports found gems" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/capistrano/))
      end
    end

    context "when Gemfile.lock is missing" do
      it "adds a warning about missing lockfile" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/Gemfile\.lock not found/))
      end
    end

    context "with deployment stages" do
      before do
        create_file("config/deploy/production.rb", "")
        create_file("config/deploy/staging.rb", "")
      end

      it "reports defined stages" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/production/))
      end

      context "when required_stages includes a missing stage" do
        it "adds an error for the missing stage" do
          result = build_check(required_stages: ["production", "qa"]).run
          expect(result.errors).to include(a_string_matching(/qa/))
        end

        it "does not error for existing stages" do
          result = build_check(required_stages: ["production"]).run
          expect(result.errors).to be_empty
        end
      end
    end
  end
end
