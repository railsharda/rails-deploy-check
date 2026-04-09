require "spec_helper"
require "rails_deploy_check/checks/secrets_check"

RSpec.describe RailsDeployCheck::Checks::SecretsCheck do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(tmpdir) }

  def create_file(relative_path, content = "")
    full_path = File.join(tmpdir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def build_check(options = {})
    described_class.new({ app_path: tmpdir, rails_env: "production" }.merge(options))
  end

  describe "#run" do
    context "master key checks" do
      it "reports info when RAILS_MASTER_KEY env var is set" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("RAILS_MASTER_KEY").and_return("abc123")

        result = build_check.run
        expect(result.infos).to include(match(/RAILS_MASTER_KEY environment variable is set/))
      end

      it "reports info when config/master.key file exists" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("RAILS_MASTER_KEY").and_return(nil)
        create_file("config/master.key", "somesecretkey")

        result = build_check.run
        expect(result.infos).to include(match(/master.key file is present/))
      end

      it "reports error when no master key is found" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("RAILS_MASTER_KEY").and_return(nil)

        result = build_check.run
        expect(result.errors).to include(match(/No master key found/))
      end

      it "skips master key check when check_master_key is false" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("RAILS_MASTER_KEY").and_return(nil)

        result = build_check(check_master_key: false).run
        expect(result.errors).not_to include(match(/No master key found/))
      end
    end

    context "credentials file checks" do
      it "reports info for environment-specific credentials file" do
        create_file("config/credentials/production.yml.enc", "encrypted")
        result = build_check.run
        expect(result.infos).to include(match(/production.yml.enc/))
      end

      it "reports info for default credentials file" do
        create_file("config/credentials.yml.enc", "encrypted")
        result = build_check.run
        expect(result.infos).to include(match(/credentials.yml.enc/))
      end

      it "reports warning when no credentials file found" do
        result = build_check.run
        expect(result.warnings).to include(match(/No encrypted credentials file found/))
      end
    end

    context "SECRET_KEY_BASE checks" do
      it "reports info when SECRET_KEY_BASE is long enough" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SECRET_KEY_BASE").and_return("a" * 64)

        result = build_check.run
        expect(result.infos).to include(match(/SECRET_KEY_BASE environment variable is set/))
      end

      it "reports error when SECRET_KEY_BASE is too short" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SECRET_KEY_BASE").and_return("short")

        result = build_check.run
        expect(result.errors).to include(match(/appears too short/))
      end
    end

    context ".env gitignore checks" do
      it "reports warning when .env exists but is not in .gitignore" do
        create_file(".env", "SECRET=value")
        create_file(".gitignore", "*.log\ntmp/\n")

        result = build_check.run
        expect(result.warnings).to include(match(/not listed in .gitignore/))
      end

      it "does not warn when .env is listed in .gitignore" do
        create_file(".env", "SECRET=value")
        create_file(".gitignore", ".env\n*.log\n")

        result = build_check.run
        expect(result.warnings).not_to include(match(/.env/))
      end
    end
  end
end
