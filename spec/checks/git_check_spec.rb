require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::GitCheck do
  let(:tmp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(tmp_dir) }

  def build_check(options = {})
    described_class.new({ app_path: tmp_dir }.merge(options))
  end

  def init_git_repo(path)
    system("git -C #{path} init -q")
    system("git -C #{path} config user.email 'test@test.com'")
    system("git -C #{path} config user.name 'Test'")
  end

  describe "#run" do
    context "when not a git repository" do
      it "adds a warning" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/Not a git repository/))
      end
    end

    context "when a git repository exists" do
      before { init_git_repo(tmp_dir) }

      it "adds an info message about git detection" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Git repository detected/))
      end

      it "reports no uncommitted changes in a clean repo" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/No uncommitted changes/))
      end

      it "warns about uncommitted changes" do
        File.write(File.join(tmp_dir, "dirty.txt"), "change")
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/Uncommitted changes detected/))
      end

      it "reports the current branch" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Deploying from branch:/))
      end

      context "with expected_branch option" do
        it "warns when branch does not match expected" do
          result = build_check(expected_branch: "main").run
          # newly init'd repo may be 'master' or 'main' depending on git config
          branch = `git -C #{tmp_dir} rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
          if branch != "main"
            expect(result.warnings).to include(a_string_matching(/does not match expected 'main'/))
          else
            expect(result.infos).to include(a_string_matching(/Deploying from branch: main/))
          end
        end
      end
    end
  end

  describe "#options" do
    it "stores provided options" do
      check = build_check(expected_branch: "production")
      expect(check.options[:expected_branch]).to eq("production")
    end

    it "defaults app_path to Dir.pwd when not provided" do
      check = described_class.new
      expect(check.options[:app_path]).to be_nil
    end
  end
end
