# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::DatabasePoolCheck do
  def build_check(app_path:, **opts)
    described_class.new(app_path: app_path, **opts)
  end

  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  it "reports an error when database.yml is missing" do
    with_tmp_rails_app do |app_path|
      result = build_check(app_path: app_path).run
      expect(result.errors).to include(a_string_matching(/database.yml not found/))
    end
  end

  it "reports info when database.yml exists" do
    with_tmp_rails_app do |app_path|
      create_file(File.join(app_path, "config", "database.yml"), "adapter: postgresql\npool: 5\n")
      result = build_check(app_path: app_path).run
      expect(result.infos).to include(a_string_matching(/database.yml found/))
    end
  end

  it "warns when no pool size is configured" do
    with_tmp_rails_app do |app_path|
      create_file(File.join(app_path, "config", "database.yml"), "adapter: postgresql\n")
      result = build_check(app_path: app_path).run
      expect(result.warnings).to include(a_string_matching(/No pool size configured/))
    end
  end

  it "reports info when pool size is explicitly set" do
    with_tmp_rails_app do |app_path|
      create_file(File.join(app_path, "config", "database.yml"), "adapter: postgresql\npool: 10\n")
      result = build_check(app_path: app_path).run
      expect(result.infos).to include(a_string_matching(/explicitly configured/))
    end
  end

  it "warns when pool size is below minimum" do
    with_tmp_rails_app do |app_path|
      create_file(File.join(app_path, "config", "database.yml"), "adapter: postgresql\npool: 1\n")
      result = build_check(app_path: app_path, min_pool_size: 2).run
      expect(result.warnings).to include(a_string_matching(/below recommended minimum/))
    end
  end

  it "warns when pool size exceeds maximum" do
    with_tmp_rails_app do |app_path|
      create_file(File.join(app_path, "config", "database.yml"), "adapter: postgresql\npool: 200\n")
      result = build_check(app_path: app_path, max_pool_size: 100).run
      expect(result.warnings).to include(a_string_matching(/exceeds recommended maximum/))
    end
  end

  it "reports info when pool size is within range" do
    with_tmp_rails_app do |app_path|
      create_file(File.join(app_path, "config", "database.yml"), "adapter: postgresql\npool: 10\n")
      result = build_check(app_path: app_path).run
      expect(result.infos).to include(a_string_matching(/within acceptable range/))
    end
  end

  it "warns when adapter is unrecognized" do
    with_tmp_rails_app do |app_path|
      create_file(File.join(app_path, "config", "database.yml"), "adapter: oracle\npool: 5\n")
      result = build_check(app_path: app_path).run
      expect(result.warnings).to include(a_string_matching(/Unrecognized database adapter/))
    end
  end

  it "reports info for a known adapter" do
    with_tmp_rails_app do |app_path|
      create_file(File.join(app_path, "config", "database.yml"), "adapter: mysql2\npool: 5\n")
      result = build_check(app_path: app_path).run
      expect(result.infos).to include(a_string_matching(/mysql2.*recognized/))
    end
  end
end
