# frozen_string_literal: true
# Integration helper: registers SidekiqCheck with default options when
# Sidekiq is detected in the Gemfile.lock.

require_relative "sidekiq_check"

module RailsDeployCheck
  module Checks
    module SidekiqCheckIntegration
      GEMFILE_LOCK_PATH = File.join(Dir.pwd, "Gemfile.lock")

      # Returns a SidekiqCheck instance pre-configured from the environment,
      # or nil if Sidekiq is not listed in Gemfile.lock.
      #
      # @param options [Hash] overrides passed through to SidekiqCheck
      # @return [SidekiqCheck, nil]
      def self.build(options = {})
        return nil unless sidekiq_in_lockfile?

        defaults = {
          redis_url: ENV["REDIS_URL"] || ENV["SIDEKIQ_REDIS_URL"],
          require_sidekiq: true,
          app_path: Dir.pwd
        }

        SidekiqCheck.new(defaults.merge(options))
      end

      # Registers a SidekiqCheck into the given configuration block if Sidekiq
      # is present in the Gemfile.lock.
      #
      # Usage:
      #   RailsDeployCheck.configure do |config|
      #     RailsDeployCheck::Checks::SidekiqCheckIntegration.register(config)
      #   end
      #
      # @param config [RailsDeployCheck::Configuration]
      # @param options [Hash]
      def self.register(config, options = {})
        check = build(options)
        config.checks << check if check
      end

      def self.sidekiq_in_lockfile?
        return false unless File.exist?(GEMFILE_LOCK_PATH)

        File.readlines(GEMFILE_LOCK_PATH).any? { |line| line.strip.start_with?("sidekiq ") }
      end
      private_class_method :sidekiq_in_lockfile?
    end
  end
end
