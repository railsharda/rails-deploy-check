# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class ConnectionTimeoutCheck
      CHECK_NAME = "Connection Timeout"

      KNOWN_TIMEOUT_KEYS = %w[
        connect_timeout
        read_timeout
        write_timeout
        checkout_timeout
      ].freeze

      DEFAULT_WARN_THRESHOLD = 30
      DEFAULT_ERROR_THRESHOLD = 120

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @warn_threshold = options.fetch(:warn_threshold, DEFAULT_WARN_THRESHOLD)
        @error_threshold = options.fetch(:error_threshold, DEFAULT_ERROR_THRESHOLD)
      end

      def run
        result = Result.new(CHECK_NAME)
        check_database_yml_timeouts(result)
        check_connect_timeout_env(result)
        result
      end

      private

      def check_database_yml_timeouts(result)
        db_yml = File.join(@app_path, "config", "database.yml")

        unless File.exist?(db_yml)
          result.add_info("database.yml not found, skipping timeout checks")
          return
        end

        content = File.read(db_yml)

        if content.match?(/connect_timeout\s*:\s*(\d+)/)
          value = content.match(/connect_timeout\s*:\s*(\d+)/)[1].to_i
          if value >= @error_threshold
            result.add_error("connect_timeout is #{value}s which exceeds error threshold of #{@error_threshold}s")
          elsif value >= @warn_threshold
            result.add_warning("connect_timeout is #{value}s which exceeds warning threshold of #{@warn_threshold}s")
          else
            result.add_info("connect_timeout is set to #{value}s")
          end
        else
          result.add_warning("No connect_timeout configured in database.yml — connections may hang indefinitely")
        end

        if content.match?(/checkout_timeout\s*:\s*(\d+)/)
          value = content.match(/checkout_timeout\s*:\s*(\d+)/)[1].to_i
          result.add_info("checkout_timeout is set to #{value}s")
        else
          result.add_warning("No checkout_timeout configured in database.yml — connection pool checkouts may block")
        end
      end

      def check_connect_timeout_env(result)
        timeout_env = ENV["DATABASE_CONNECT_TIMEOUT"] || ENV["DB_CONNECT_TIMEOUT"]
        return unless timeout_env

        value = timeout_env.to_i
        if value >= @error_threshold
          result.add_error("DATABASE_CONNECT_TIMEOUT env is #{value}s, exceeds error threshold of #{@error_threshold}s")
        elsif value >= @warn_threshold
          result.add_warning("DATABASE_CONNECT_TIMEOUT env is #{value}s, exceeds warning threshold of #{@warn_threshold}s")
        else
          result.add_info("DATABASE_CONNECT_TIMEOUT env is set to #{value}s")
        end
      end
    end
  end
end
