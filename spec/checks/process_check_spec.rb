require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::ProcessCheck do
  let(:tmp_dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(tmp_dir) }

  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new({ app_root: tmp_dir }.merge(options))
  end

  describe "#run" do
    context "when Procfile does not exist" do
      it "returns an error" do
        result = build_check.run
        expect(result.errors).to include(a_string_matching(/Procfile not found/))
      end
    end

    context "when Procfile exists" do
      before do
        create_file(
          File.join(tmp_dir, "Procfile"),
          "web: bundle exec puma -C config/puma.rb\nworker: bundle exec sidekiq\n"
        )
      end

      it "reports Procfile found" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/Procfile found/))
      end

      it "reports required process types as defined" do
        result = build_check.run
        expect(result.infos).to include(a_string_matching(/'web' is defined/))
        expect(result.infos).to include(a_string_matching(/'worker' is defined/))
      end

      it "has no errors" do
        result = build_check.run
        expect(result.errors).to be_empty
      end
    end

    context "when a required process type is missing" do
      before do
        create_file(
          File.join(tmp_dir, "Procfile"),
          "web: bundle exec puma -C config/puma.rb\n"
        )
      end

      it "warns about missing process type" do
        result = build_check.run
        expect(result.warnings).to include(a_string_matching(/'worker' is not defined/))
      end
    end

    context "when Procfile has duplicate process types" do
      before do
        create_file(
          File.join(tmp_dir, "Procfile"),
          "web: bundle exec puma\nweb: bundle exec unicorn\nworker: bundle exec sidekiq\n"
        )
      end

      it "reports an error for the duplicate" do
        result = build_check.run
        expect(result.errors).to include(a_string_matching(/Duplicate process type 'web'/))
      end
    end

    context "with custom required processes" do
      before do
        create_file(
          File.join(tmp_dir, "Procfile"),
          "web: bundle exec puma\nclock: bundle exec clockwork\n"
        )
      end

      it "checks only the specified process types" do
        result = build_check(required_processes: %w[web clock]).run
        expect(result.warnings).to be_empty
        expect(result.errors).to be_empty
      end
    end
  end
end
