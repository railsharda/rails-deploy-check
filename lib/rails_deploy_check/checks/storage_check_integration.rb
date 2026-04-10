# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module StorageCheckIntegration
      # Builds a StorageCheck instance if Active Storage appears to be in use.
      # Returns nil if there is no indication that Active Storage is configured.
      def self.build(options = {})
        app_path = options.fetch(:app_path, Dir.pwd)
        return nil unless active_storage_present?(app_path)

        StorageCheck.new(options)
      end

      # Registers StorageCheck into the given configuration if applicable.
      def self.register(config, options = {})
        check = build(options)
        config.checks << check if check
        check
      end

      def self.active_storage_present?(app_path)
        storage_yml = File.join(app_path, "config", "storage.yml")
        lockfile = File.join(app_path, "Gemfile.lock")

        return true if File.exist?(storage_yml)
        return true if File.exist?(lockfile) && File.read(lockfile).include?("activestorage")

        false
      end
    end
  end
end
