# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::ConnectionPoolCheck do
  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  context "when database.yml does not exist" do
    it "adds a warning" do
      with_tmp_rails_app do |app_path|
        check = build_check(app_path: app_path)
        result = check.run
        expect(result.warnings.first).to match(/database\.yml not found/)
      end
    end
  end

  context "when database.yml exists" do
    context "without pool configured" do
      it "warns about missing pool size" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "database.yml"), <<~YAML)
            production:
              adapter: postgresql
              database: myapp_production
          YAML

          result = build_check(app_path: app_path).run
          expect(result.warnings.first).to match(/No pool size configured/)
        end
      end
    end

    context "with pool size below minimum" do
      it "adds an error" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "database.yml"), <<~YAML)
            production:
              adapter: postgresql
              pool: 1
          YAML

          result = build_check(app_path: app_path, min_pool_size: 2).run
          expect(result.errors.first).to match(/below minimum/)
        end
      end
    end

    context "with small but acceptable pool size" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "database.yml"), <<~YAML)
            production:
              adapter: postgresql
              pool: 3
          YAML

          result = build_check(app_path: app_path, min_pool_size: 2, warn_pool_size: 5).run
          expect(result.warnings.first).to match(/may be too small/)
        end
      end
    end

    context "with a healthy pool size" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "database.yml"), <<~YAML)
            production:
              adapter: postgresql
              pool: 10
          YAML

          result = build_check(app_path: app_path).run
          expect(result.infos.first).to match(/Connection pool size is 10/)
          expect(result.errors).to be_empty
          expect(result.warnings).to be_empty
        end
      end
    end

    context "with an excessively large pool size" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "database.yml"), <<~YAML)
            production:
              adapter: postgresql
              pool: 30
          YAML

          result = build_check(app_path: app_path, max_pool_size: 25).run
          expect(result.warnings.first).to match(/very large/)
        end
      end
    end

    context "with ERB pool value" do
      it "skips numeric validation" do
        with_tmp_rails_app do |app_path|
          create_file(File.join(app_path, "config", "database.yml"), <<~YAML)
            production:
              adapter: postgresql
              pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
          YAML

          result = build_check(app_path: app_path).run
          expect(result.errors).to be_empty
        end
      end
    end
  end
end
