# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module FeatureFlagsCheckIntegration
      def self.build(options = {})
        FeatureFlagsCheck.new(options)
      end

      def self.register(registry, options = {})
        return unless applicable?(options)

        registry << build(options)
      end

      def self.applicable?(options = {})
        app_path = options.fetch(:app_path, Dir.pwd)
        flipper_in_lockfile?(app_path) || flipper_initializer_present?(app_path)
      end

      def self.flipper_in_lockfile?(app_path = Dir.pwd)
        lockfile = File.join(app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).match?(/^\s+flipper/)
      end

      def self.flipper_initializer_present?(app_path = Dir.pwd)
        File.exist?(File.join(app_path, "config", "initializers", "flipper.rb")) ||
          File.exist?(File.join(app_path, "config", "flipper.yml"))
      end
    end
  end
end
