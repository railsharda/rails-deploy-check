# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/puma_check"
require "rails_deploy_check/checks/puma_check_integration"

RSpec.describe RailsDeployCheck::Checks::PumaCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  context "when no puma config file exists" do
    it "adds a warning" do
      with_tmp_rails_app do |app_path|
        result = build_check(app_path: app_path).run
        expect(result.warnings.first).to include("No Puma config file found")
      end
    end
  end

  context "when config/puma.rb exists" do
    it "reports config found" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/config/puma.rb", "workers 2\nthreads 1, 5\nbind 'tcp://0.0.0.0:3000'\n")
        result = build_check(app_path: app_path).run
        expect(result.infos.any? { |i| i.include?("config/puma.rb") }).to be true
      end
    end

    it "reports workers configured" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/config/puma.rb", "workers 3\nthreads 1, 5\nbind 'tcp://0.0.0.0:3000'\n")
        result = build_check(app_path: app_path).run
        expect(result.infos.any? { |i| i.include?("workers") }).to be true
        expect(result.warnings).to be_empty
      end
    end

    it "warns when workers not configured" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/config/puma.rb", "threads 1, 5\nbind 'tcp://0.0.0.0:3000'\n")
        result = build_check(app_path: app_path).run
        expect(result.warnings.any? { |w| w.include?("workers") }).to be true
      end
    end

    it "warns when threads not configured" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/config/puma.rb", "workers 2\nbind 'tcp://0.0.0.0:3000'\n")
        result = build_check(app_path: app_path).run
        expect(result.warnings.any? { |w| w.include?("threads") }).to be true
      end
    end

    it "warns when bind/port not configured" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/config/puma.rb", "workers 2\nthreads 1, 5\n")
        result = build_check(app_path: app_path).run
        expect(result.warnings.any? { |w| w.include?("bind or port") }).to be true
      end
    end

    it "accepts port directive as alternative to bind" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/config/puma.rb", "workers 2\nthreads 1, 5\nport ENV.fetch('PORT', 3000)\n")
        result = build_check(app_path: app_path).run
        expect(result.warnings.any? { |w| w.include?("bind or port") }).to be false
      end
    end
  end

  context "when config/puma/production.rb exists" do
    it "finds the production-specific config" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/config/puma/production.rb", "workers 2\nthreads 2, 4\nbind 'tcp://0.0.0.0:3000'\n")
        result = build_check(app_path: app_path).run
        expect(result.infos.any? { |i| i.include?("config/puma/production.rb") }).to be true
      end
    end
  end
end

RSpec.describe RailsDeployCheck::Checks::PumaCheckIntegration do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  describe ".applicable?" do
    it "returns true when puma is in Gemfile.lock" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/Gemfile.lock", "    puma (6.0.0)\n")
        expect(described_class.applicable?(app_path: app_path)).to be true
      end
    end

    it "returns true when puma config file exists" do
      with_tmp_rails_app do |app_path|
        create_file("#{app_path}/config/puma.rb", "")
        expect(described_class.applicable?(app_path: app_path)).to be true
      end
    end

    it "returns false when neither condition is met" do
      with_tmp_rails_app do |app_path|
        expect(described_class.applicable?(app_path: app_path)).to be false
      end
    end
  end
end
