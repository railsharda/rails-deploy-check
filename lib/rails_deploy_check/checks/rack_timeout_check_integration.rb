# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module RackTimeoutCheckIntegration
      def self.build(options = {})
        RackTimeoutCheck.new(options)
      end

      def self.register(registry, options = {})
        return unless applicable?(options)

        registry << build(options)
      end

      def self.applicable?(options = {})
        app_path = options.fetch(:app_path, Dir.pwd)
        rack_timeout_in_lockfile?(app_path) || rack_timeout_env_present?
      end

      def self.rack_timeout_in_lockfile?(app_path = Dir.pwd)
        lockfile = File.join(app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).include?("rack-timeout")
      end

      def self.rack_timeout_env_present?
        ENV.key?("RACK_TIMEOUT_SERVICE_TIMEOUT") ||
          ENV.key?("RACK_TIMEOUT_WAIT_TIMEOUT")
      end
    end
  end
end
