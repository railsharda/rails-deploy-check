require "spec_helper"
require "rails_deploy_check/checks/dependency_check"
require "rails_deploy_check/checks/dependency_check_integration"

RSpec.describe RailsDeployCheck::Checks::DependencyCheckIntegration do
  describe ".build" do
    it "returns a DependencyCheck instance" do
      check = described_class.build(rails_root: Dir.pwd)
      expect(check).to be_a(RailsDeployCheck::Checks::DependencyCheck)
    end

    it "passes config to the check" do
      check = described_class.build(rails_root: "/custom/path")
      expect(check.config[:rails_root]).to eq("/custom/path")
    end
  end

  describe ".register" do
    it "registers the check in the registry" do
      registry = {}
      described_class.register(registry, rails_root: Dir.pwd)
      expect(registry[:dependency]).to be_a(RailsDeployCheck::Checks::DependencyCheck)
    end
  end

  describe ".gemfile_present?" do
    it "returns true when Gemfile exists" do
      with_tmp_rails_app do |dir|
        File.write(File.join(dir, "Gemfile"), "source 'https://rubygems.org'")
        expect(described_class.gemfile_present?(dir)).to be true
      end
    end

    it "returns false when Gemfile is missing" do
      with_tmp_rails_app do |dir|
        FileUtils.rm_f(File.join(dir, "Gemfile"))
        expect(described_class.gemfile_present?(dir)).to be false
      end
    end
  end

  describe ".applicable?" do
    it "returns true when Gemfile exists" do
      with_tmp_rails_app do |dir|
        File.write(File.join(dir, "Gemfile"), "source 'https://rubygems.org'")
        expect(described_class.applicable?(dir)).to be true
      end
    end

    it "returns false when Gemfile does not exist" do
      with_tmp_rails_app do |dir|
        FileUtils.rm_f(File.join(dir, "Gemfile"))
        expect(described_class.applicable?(dir)).to be false
      end
    end
  end
end
