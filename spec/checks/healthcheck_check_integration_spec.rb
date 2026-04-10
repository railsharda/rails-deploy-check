require "spec_helper"
require "rails_deploy_check/checks/healthcheck_check_integration"

RSpec.describe RailsDeployCheck::Checks::HealthcheckCheckIntegration do
  subject(:integration) { described_class }

  around do |example|
    with_tmp_rails_app { |dir| @tmpdir = dir; example.run }
  end

  describe ".applicable?" do
    it "returns true when config/routes.rb exists" do
      FileUtils.mkdir_p(File.join(@tmpdir, "config"))
      File.write(File.join(@tmpdir, "config", "routes.rb"), "")
      expect(integration.applicable?(@tmpdir)).to be true
    end

    it "returns false when config/routes.rb is absent" do
      expect(integration.applicable?(@tmpdir)).to be false
    end
  end

  describe ".detected_paths" do
    it "returns matched paths from routes.rb" do
      FileUtils.mkdir_p(File.join(@tmpdir, "config"))
      File.write(
        File.join(@tmpdir, "config", "routes.rb"),
        "get 'up', to: 'rails/health#show'\nget 'ping', to: 'pings#show'"
      )
      paths = integration.detected_paths(@tmpdir)
      expect(paths).to include("/up", "/ping")
    end

    it "returns empty array when no paths match" do
      FileUtils.mkdir_p(File.join(@tmpdir, "config"))
      File.write(File.join(@tmpdir, "config", "routes.rb"), "root 'home#index'")
      expect(integration.detected_paths(@tmpdir)).to be_empty
    end
  end

  describe ".build" do
    it "returns a HealthcheckCheck instance" do
      check = integration.build(app_root: @tmpdir)
      expect(check).to be_a(RailsDeployCheck::Checks::HealthcheckCheck)
    end
  end
end
