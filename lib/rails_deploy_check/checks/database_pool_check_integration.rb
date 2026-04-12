# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module DatabasePoolCheckIntegration
      def self.build(config = {})
        DatabasePoolCheck.new(
          app_path: config.fetch(:app_path, Dir.pwd),
          min_pool_size: config.fetch(:min_pool_size, DatabasePoolCheck::DEFAULT_MIN_POOL_SIZE),
          max_pool_size: config.fetch(:max_pool_size, DatabasePoolCheck::DEFAULT_MAX_POOL_SIZE)
        )
      end

      def self.register(registry)
        return unless applicable?

        registry.register(:database_pool, method(:build))
      end

      def self.applicable?
        database_yml_present? || active_record_present?
      end

      def self.database_yml_present?
        File.exist?(File.join(Dir.pwd, "config", "database.yml"))
      end

      def self.active_record_present?
        lockfile = File.join(Dir.pwd, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).include?("activerecord")
      end
    end
  end
end
