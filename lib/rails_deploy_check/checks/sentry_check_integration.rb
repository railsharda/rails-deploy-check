# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module SentryCheckIntegration
      def self.build(options = {})
        SentryCheck.new(options)
      end

      def self.register
        RailsDeployCheck.configuration.register_check(:sentry, method(:build)) if applicable?
      end

      # Auto-register when the Sentry gem is present in the lockfile or the
      # SENTRY_DSN variable is already set in the environment.
      def self.applicable?
        sentry_dsn_present? || sentry_in_lockfile?
      end

      def self.sentry_dsn_present?
        dsn = ENV["SENTRY_DSN"]
        !dsn.nil? && !dsn.strip.empty?
      end

      def self.sentry_in_lockfile?(app_path: Dir.pwd)
        lockfile = File.join(app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        content = File.read(lockfile)
        content.match?(/^\s+sentry-ruby\b/) || content.match?(/^\s+sentry-rails\b/)
      end
    end
  end
end
