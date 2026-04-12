# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class DatabasePoolCheck
      attr_reader :result

      DEFAULT_MIN_POOL_SIZE = 2
      DEFAULT_MAX_POOL_SIZE = 100
      KNOWN_ADAPTERS = %w[postgresql mysql2 sqlite3 trilogy].freeze

      def initialize(app_path: Dir.pwd, min_pool_size: DEFAULT_MIN_POOL_SIZE, max_pool_size: DEFAULT_MAX_POOL_SIZE)
        @app_path = app_path
        @min_pool_size = min_pool_size
        @max_pool_size = max_pool_size
        @result = Result.new("Database Pool")
      end

      def run
        check_database_yml_exists
        check_pool_size_configured
        check_pool_size_reasonable
        check_adapter_known
        result
      end

      private

      def check_database_yml_exists
        unless File.exist?(database_yml_path)
          result.add_error("database.yml not found at #{database_yml_path}")
          return
        end
        result.add_info("database.yml found")
      end

      def check_pool_size_configured
        return unless File.exist?(database_yml_path)

        content = File.read(database_yml_path)
        unless content.match?(/pool[:\s]/)
          result.add_warning("No pool size configured in database.yml; Rails default (5) will be used")
          return
        end
        result.add_info("Database pool size is explicitly configured")
      end

      def check_pool_size_reasonable
        return unless File.exist?(database_yml_path)

        content = File.read(database_yml_path)
        pool_match = content.match(/pool[:\s]+['"]?(\d+)['"]?/)
        return unless pool_match

        pool_size = pool_match[1].to_i
        if pool_size < @min_pool_size
          result.add_warning("Pool size (#{pool_size}) is below recommended minimum (#{@min_pool_size})")
        elsif pool_size > @max_pool_size
          result.add_warning("Pool size (#{pool_size}) exceeds recommended maximum (#{@max_pool_size}); may exhaust DB connections")
        else
          result.add_info("Pool size (#{pool_size}) is within acceptable range")
        end
      end

      def check_adapter_known
        return unless File.exist?(database_yml_path)

        content = File.read(database_yml_path)
        adapter_match = content.match(/adapter[:\s]+['"]?(\S+?)['"]?\s*$/)
        return unless adapter_match

        adapter = adapter_match[1]
        unless KNOWN_ADAPTERS.include?(adapter)
          result.add_warning("Unrecognized database adapter '#{adapter}'; ensure it is properly configured")
          return
        end
        result.add_info("Database adapter '#{adapter}' is recognized")
      end

      def database_yml_path
        File.join(@app_path, "config", "database.yml")
      end
    end
  end
end
