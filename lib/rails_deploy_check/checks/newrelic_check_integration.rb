# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module NewrelicCheckIntegration
      def self.build(config = {})
        NewrelicCheck.new(
          app_root: config.fetch(:app_root, Dir.pwd),
          license_key: config[:new_relic_license_key],
          app_name: config[:new_relic_app_name]
        )
      end

      def self.register(registry)
        registry.register(:newrelic, method(:build)) if applicable?
      end

      def self.applicable?
        newrelic_in_lockfile? || license_key_present?
      end

      def self.newrelic_in_lockfile?
        lockfile = File.join(Dir.pwd, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).include?("newrelic_rpm")
      end

      def self.license_key_present?
        key = ENV["NEW_RELIC_LICENSE_KEY"]
        !key.nil? && !key.strip.empty?
      end
    end
  end
end
