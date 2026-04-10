require "spec_helper"
require "rails_deploy_check/checks/docker_check"

RSpec.describe RailsDeployCheck::Checks::DockerCheck do
  def create_file(path, content = "")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when Dockerfile is present" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/Dockerfile", "FROM ruby:3.2")
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/Dockerfile found/))
        end
      end
    end

    context "when Dockerfile is missing" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/No Dockerfile found/))
        end
      end
    end

    context "when docker-compose.yml exists" do
      it "adds an info message" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/docker-compose.yml", "version: '3'\nservices:\n  web:\n")
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/Docker Compose file found/))
        end
      end

      it "warns when no production override exists" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/docker-compose.yml", "version: '3'\nservices:\n  web:\n")
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/No production Docker Compose override/))
        end
      end
    end

    context "when required services are specified" do
      it "reports info for each service found" do
        with_tmp_rails_app do |app_path|
          compose = "version: '3'\nservices:\n  web:\n    image: app\n  redis:\n    image: redis\n"
          create_file("#{app_path}/docker-compose.yml", compose)
          result = build_check(app_path: app_path, required_services: ["web", "redis"]).run
          expect(result.infos).to include(a_string_matching(/Required service 'web'/),
                                          a_string_matching(/Required service 'redis'/))
        end
      end

      it "adds an error for a missing required service" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/docker-compose.yml", "version: '3'\nservices:\n  web:\n")
          result = build_check(app_path: app_path, required_services: ["sidekiq"]).run
          expect(result.errors).to include(a_string_matching(/Required service 'sidekiq' not found/))
        end
      end
    end

    context "when .dockerignore is present" do
      it "adds info when .env is excluded" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/.dockerignore", ".env\n.env.*\n")
          result = build_check(app_path: app_path).run
          expect(result.infos).to include(a_string_matching(/.env files excluded/))
        end
      end

      it "warns when .env is not excluded" do
        with_tmp_rails_app do |app_path|
          create_file("#{app_path}/.dockerignore", "log/\ntmp/\n")
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/does not exclude .env files/))
        end
      end
    end

    context "when .dockerignore is missing" do
      it "adds a warning" do
        with_tmp_rails_app do |app_path|
          result = build_check(app_path: app_path).run
          expect(result.warnings).to include(a_string_matching(/No .dockerignore found/))
        end
      end
    end
  end
end
