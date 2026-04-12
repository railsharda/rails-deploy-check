# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module LoadAverageCheckIntegration
      def self.build(options = {})
        LoadAverageCheck.new(
          warning_threshold: options.fetch(:warning_threshold, LoadAverageCheck::DEFAULT_WARNING_THRESHOLD),
          critical_threshold: options.fetch(:critical_threshold, LoadAverageCheck::DEFAULT_CRITICAL_THRESHOLD)
        )
      end

      def self.register(config)
        return unless applicable?

        config.checks << build(
          warning_threshold: config.load_average_warning_threshold,
          critical_threshold: config.load_average_critical_threshold
        )
      end

      def self.applicable?
        linux? || macos?
      end

      def self.linux?
        RbConfig::CONFIG["host_os"] =~ /linux/i
      end

      def self.macos?
        RbConfig::CONFIG["host_os"] =~ /darwin/i
      end
    end
  end
end
