# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class CiCheck
      CI_ENV_VARS = %w[
        CI
        GITHUB_ACTIONS
        CIRCLECI
        TRAVIS
        GITLAB_CI
        BUILDKITE
        JENKINS_URL
      ].freeze

      REQUIRED_CI_FILES = {
        github_actions: ".github/workflows",
        circleci: ".circleci/config.yml",
        travis: ".travis.yml",
        gitlab: ".gitlab-ci.yml",
        buildkite: ".buildkite/pipeline.yml"
      }.freeze

      def initialize(config = {})
        @app_path = config.fetch(:app_path, Dir.pwd)
        @require_ci = config.fetch(:require_ci, false)
        @require_ci_passing = config.fetch(:require_ci_passing, false)
      end

      def run
        result = Result.new("CI Configuration")

        check_ci_environment(result)
        check_ci_config_file(result)
        check_ci_status(result) if @require_ci_passing

        result
      end

      private

      def check_ci_environment(result)
        detected = CI_ENV_VARS.select { |var| ENV[var].to_s.strip != "" }

        if detected.any?
          result.add_info("CI environment detected via: #{detected.join(', ')}")
        elsif @require_ci
          result.add_error("No CI environment detected. Deployment requires a CI environment.")
        else
          result.add_warning("No CI environment detected. Consider running deployments from CI.")
        end
      end

      def check_ci_config_file(result)
        found = REQUIRED_CI_FILES.select do |_provider, path|
          full_path = File.join(@app_path, path)
          File.exist?(full_path)
        end

        if found.any?
          found.each do |provider, path|
            result.add_info("CI config found for #{provider}: #{path}")
          end
        else
          result.add_warning("No CI configuration file found (e.g. .github/workflows, .circleci/config.yml).")
        end
      end

      def check_ci_status(result)
        status = ENV["CI_JOB_STATUS"] || ENV["GITHUB_JOB"] || ENV["CIRCLE_JOB"]
        if status
          result.add_info("CI job detected: #{status}")
        else
          result.add_warning("Could not determine CI job status from environment.")
        end
      end
    end
  end
end
