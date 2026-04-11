require "spec_helper"
require "rails_deploy_check/checks/env_file_check"

RSpec.describe RailsDeployCheck::Checks::EnvFileCheck do
  def create_file(dir, name, content = "")
    path = File.join(dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def build_check(dir, **opts)
    described_class.new(app_path: dir, **opts)
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  describe "#run" do
    context "when .env exists and is in .gitignore" do
      before do
        create_file(@dir, ".env", "DATABASE_URL=postgres://localhost/myapp")
        create_file(@dir, ".gitignore", ".env\n.DS_Store\n")
      end

      it "does not add an error" do
        result = build_check(@dir).run
        expect(result.errors).to be_empty
      end

      it "adds a warning that .env is present on disk" do
        result = build_check(@dir).run
        expect(result.warnings).to include(match(/\.env file exists on disk/))
      end
    end

    context "when .env exists but is NOT in .gitignore" do
      before do
        create_file(@dir, ".env", "SECRET=abc")
        create_file(@dir, ".gitignore", "log/\ntmp/\n")
      end

      it "adds an error" do
        result = build_check(@dir).run
        expect(result.errors).to include(match(/not listed in \.gitignore/))
      end
    end

    context "when .env does not exist" do
      it "adds an info message" do
        result = build_check(@dir).run
        expect(result.errors).to be_empty
        expect(result.infos).to include(match(/not present on disk/))
      end
    end

    context "when .env.example is present" do
      before do
        create_file(@dir, ".env.example", "DATABASE_URL=\nSECRET_KEY_BASE=\nREDIS_URL=\n")
      end

      it "adds an info message about the example file" do
        result = build_check(@dir).run
        expect(result.infos).to include(match(/\.env\.example/))
      end

      context "with required_keys all present in example" do
        it "adds an info message confirming all keys documented" do
          result = build_check(@dir, required_keys: %w[DATABASE_URL SECRET_KEY_BASE]).run
          expect(result.infos).to include(match(/All required keys are documented/))
        end
      end

      context "with a required key missing from example" do
        it "adds a warning for the missing key" do
          result = build_check(@dir, required_keys: %w[DATABASE_URL STRIPE_API_KEY]).run
          expect(result.warnings).to include(match(/STRIPE_API_KEY/))
        end
      end
    end

    context "when no example file is present" do
      it "adds a warning" do
        result = build_check(@dir).run
        expect(result.warnings).to include(match(/No \.env\.example/))
      end
    end

    context "when warn_if_dotenv_present is false" do
      before do
        create_file(@dir, ".env", "FOO=bar")
        create_file(@dir, ".gitignore", ".env\n")
      end

      it "does not warn about .env being present" do
        result = build_check(@dir, warn_if_dotenv_present: false).run
        expect(result.warnings).not_to include(match(/exists on disk/))
      end
    end
  end
end
