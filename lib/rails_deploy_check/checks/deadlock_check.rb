# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class DeadlockCheck
      attr_reader :result

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @database_yml_path = options[:database_yml_path]
        @result = Result.new("DeadlockCheck")
      end

      def run
        check_database_yml_exists
        check_lock_timeout_configured
        check_statement_timeout_configured
        result
      end

      private

      def check_database_yml_exists
        unless File.exist?(database_yml_path)
          result.add_warning("database.yml not found at #{database_yml_path}; cannot check deadlock settings")
          return
        end
        result.add_info("database.yml found at #{database_yml_path}")
      end

      def check_lock_timeout_configured
        return unless File.exist?(database_yml_path)

        content = File.read(database_yml_path)
        if content.match?(/lock_timeout/)
          result.add_info("lock_timeout is configured in database.yml")
        else
          result.add_warning("lock_timeout not set in database.yml; consider setting it to prevent long-running locks")
        end
      end

      def check_statement_timeout_configured
        return unless File.exist?(database_yml_path)

        content = File.read(database_yml_path)
        if content.match?(/statement_timeout/)
          result.add_info("statement_timeout is configured in database.yml")
        else
          result.add_warning("statement_timeout not set in database.yml; consider setting it to prevent runaway queries")
        end
      end

      def database_yml_path
        @database_yml_path ||= File.join(@app_path, "config", "database.yml")
      end
    end
  end
end
