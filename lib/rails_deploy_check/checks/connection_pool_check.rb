# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class ConnectionPoolCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @min_pool_size = options.fetch(:min_pool_size, 2)
        @warn_pool_size = options.fetch(:warn_pool_size, 5)
        @max_pool_size = options.fetch(:max_pool_size, 25)
      end

      def run
        result = Result.new(name: "Connection Pool")

        check_database_yml_exists(result)
        check_pool_size_reasonable(result)
        check_pool_not_too_large(result)

        result
      end

      private

      def check_database_yml_exists(result)
        unless File.exist?(database_yml_path)
          result.add_warning("database.yml not found at #{database_yml_path}; skipping pool checks")
          return false
        end
        true
      end

      def check_pool_size_reasonable(result)
        return unless File.exist?(database_yml_path)

        pool_size = extract_pool_size

        if pool_size.nil?
          result.add_warning("No pool size configured in database.yml; Rails default (5) will be used")
        elsif pool_size < @min_pool_size
          result.add_error("Connection pool size (#{pool_size}) is below minimum recommended (#{@min_pool_size})")
        elsif pool_size < @warn_pool_size
          result.add_warning("Connection pool size (#{pool_size}) may be too small for production workloads")
        else
          result.add_info("Connection pool size is #{pool_size}")
        end
      end

      def check_pool_not_too_large(result)
        return unless File.exist?(database_yml_path)

        pool_size = extract_pool_size
        return if pool_size.nil?

        if pool_size > @max_pool_size
          result.add_warning(
            "Connection pool size (#{pool_size}) is very large (> #{@max_pool_size}); " \
            "ensure your database server supports this many connections"
          )
        end
      end

      def extract_pool_size
        content = File.read(database_yml_path)
        match = content.match(/pool:\s*(<%=.*?%>|\d+)/)
        return nil unless match

        value = match[1]
        return nil if value.start_with?("<%=")

        value.to_i
      end

      def database_yml_path
        File.join(@app_path, "config", "database.yml")
      end
    end
  end
end
