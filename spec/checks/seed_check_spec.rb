require "spec_helper"
require "rails_deploy_check/checks/seed_check"
require "rails_deploy_check/checks/seed_check_integration"

RSpec.describe RailsDeployCheck::Checks::SeedCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new({ app_path: @tmpdir }.merge(options))
  end

  around do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  describe "#run" do
    context "when seeds.rb does not exist" do
      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/No db\/seeds\.rb file found/))
      end
    end

    context "when seeds.rb exists and has seed logic" do
      before do
        create_file(File.join(@tmpdir, "db", "seeds.rb"), "User.create!(name: 'Admin')\n")
      end

      it "reports info that seed file exists" do
        result = build_check.run
        expect(result.info).to include(a_string_matching(/Seed file exists/))
      end

      it "reports info about non-comment lines" do
        result = build_check.run
        expect(result.info).to include(a_string_matching(/contains seed logic/))
      end
    end

    context "when seeds.rb exists but is empty" do
      before do
        create_file(File.join(@tmpdir, "db", "seeds.rb"), "")
      end

      it "warns that the seed file is empty" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/is empty/))
      end
    end

    context "when seeds.rb contains only comments" do
      before do
        create_file(File.join(@tmpdir, "db", "seeds.rb"), "# This file should contain seed data\n# Example: User.create!\n")
      end

      it "warns that only comments are present" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/contains only comments/))
      end
    end

    context "when check_seed_data is enabled and destructive operations are present" do
      before do
        create_file(File.join(@tmpdir, "db", "seeds.rb"), "User.delete_all\nUser.create!(name: 'Admin')\n")
      end

      it "warns about delete_all" do
        result = build_check(check_seed_data: true).run
        expect(result.warnings).to include(a_string_matching(/delete_all/))
      end
    end

    context "when check_seed_data is enabled and no destructive operations" do
      before do
        create_file(File.join(@tmpdir, "db", "seeds.rb"), "User.find_or_create_by!(name: 'Admin')\n")
      end

      it "does not warn about destructive operations" do
        result = build_check(check_seed_data: true).run
        expect(result.warnings).not_to include(a_string_matching(/delete_all|destroy_all|DROP|TRUNCATE/))
      end
    end
  end
end
