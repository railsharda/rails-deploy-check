# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module PumaCheckIntegration
      def self.build(options = {})
        PumaCheck.new(options)
      end

      def self.register(checks, options = {})
        checks << build(options) if applicable?(options)
      end

      def self.applicable?(options = {})
        app_path = options.fetch(:app_path, Dir.pwd)
        puma_in_lockfile?(app_path) || puma_config_present?(app_path)
      end

      def self.puma_in_lockfile?(app_path)
        lockfile = File.join(app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).include?("puma")
      end

      def self.puma_config_present?(app_path)
        PumaCheck::DEFAULT_CONFIG_PATHS.any? do |path|
          File.exist?(File.join(app_path, path))
        end
      end
    end
  end
end
