# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/prometheus_check"

RSpec.describe RailsDeployCheck::Checks::PrometheusCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "with no Gemfile.lock" do
      it "adds a warning about missing Gemfile.lock" do
        with_tmp_rails_app do |app_root|
          check = build_check(app_root: app_root)
          result = check.run
          expect(result.warnings.any? { |w| w.include?("Gemfile.lock not found") }).to be true
        end
      end
    end

    context "with prometheus-client gem in Gemfile.lock" do
      it "adds info about gem presence" do
        with_tmp_rails_app do |app_root|
          create_file(File.join(app_root, "Gemfile.lock"), "    prometheus-client (0.9.0)\n")
          check = build_check(app_root: app_root)
          result = check.run
          expect(result.infos.any? { |i| i.include?("prometheus client gem found") }).to be true
        end
      end
    end

    context "with no prometheus gem in Gemfile.lock" do
      it "adds a warning" do
        with_tmp_rails_app do |app_root|
          create_file(File.join(app_root, "Gemfile.lock"), "    rails (7.0.0)\n")
          check = build_check(app_root: app_root)
          result = check.run
          expect(result.warnings.any? { |w| w.include?("No prometheus-client") }).to be true
        end
      end
    end

    context "with valid PROMETHEUS_METRICS_URL" do
      it "adds info about configured URL" do
        with_tmp_rails_app do |app_root|
          check = build_check(app_root: app_root, metrics_url: "http://localhost:9090/metrics")
          result = check.run
          expect(result.infos.any? { |i| i.include?("metrics URL configured") }).to be true
        end
      end
    end

    context "with invalid PROMETHEUS_METRICS_URL" do
      it "adds an error" do
        with_tmp_rails_app do |app_root|
          check = build_check(app_root: app_root, metrics_url: "not-a-url")
          result = check.run
          expect(result.errors.any? { |e| e.include?("not a valid") }).to be true
        end
      end
    end

    context "with pushgateway URL on non-standard port" do
      it "adds a warning about non-standard port" do
        with_tmp_rails_app do |app_root|
          check = build_check(app_root: app_root, pushgateway_url: "http://localhost:8080")
          result = check.run
          expect(result.warnings.any? { |w| w.include?("non-standard port") }).to be true
        end
      end
    end

    context "with prometheus initializer present" do
      it "adds info about initializer" do
        with_tmp_rails_app do |app_root|
          create_file(File.join(app_root, "config", "initializers", "prometheus.rb"), "# prometheus config")
          check = build_check(app_root: app_root)
          result = check.run
          expect(result.infos.any? { |i| i.include?("initializer file found") }).to be true
        end
      end
    end

    context "with no prometheus initializer" do
      it "adds a warning" do
        with_tmp_rails_app do |app_root|
          check = build_check(app_root: app_root)
          result = check.run
          expect(result.warnings.any? { |w| w.include?("No Prometheus initializer") }).to be true
        end
      end
    end
  end
end
