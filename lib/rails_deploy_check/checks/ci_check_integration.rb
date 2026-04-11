# frozen_string_literal: true

require_relative "ci_check"

module RailsDeployCheck
  module Checks
    module CiCheckIntegration
      def self.build(config = {})
        CiCheck.new(
          app_path: config.fetch(:app_path, Dir.pwd),
          require_ci: config.fetch(:require_ci, false),
          require_ci_passing: config.fetch(:require_ci_passing, false)
        )
      end

      def self.register(runner)
        runner.register(:ci, method(:build))
      end

      # Returns true if any CI environment variable is currently set.
      def self.ci_environment?
        CiCheck::CI_ENV_VARS.any? { |var| ENV[var].to_s.strip != "" }
      end

      # Returns the name of the detected CI provider, or nil.
      def self.detected_provider
        return :github_actions if ENV["GITHUB_ACTIONS"].to_s.strip != ""
        return :circleci       if ENV["CIRCLECI"].to_s.strip != ""
        return :travis         if ENV["TRAVIS"].to_s.strip != ""
        return :gitlab         if ENV["GITLAB_CI"].to_s.strip != ""
        return :buildkite      if ENV["BUILDKITE"].to_s.strip != ""
        return :jenkins        if ENV["JENKINS_URL"].to_s.strip != ""
        return :generic        if ENV["CI"].to_s.strip != ""

        nil
      end

      # Returns a human-readable string describing the detected CI provider,
      # or "unknown" if no provider is detected.
      def self.detected_provider_name
        case detected_provider
        when :github_actions then "GitHub Actions"
        when :circleci       then "CircleCI"
        when :travis         then "Travis CI"
        when :gitlab         then "GitLab CI"
        when :buildkite      then "Buildkite"
        when :jenkins        then "Jenkins"
        when :generic        then "CI (generic)"
        else                      "unknown"
        end
      end
    end
  end
end
