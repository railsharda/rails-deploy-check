# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class EnvVarsCheck
      attr_reader :result

      DEFAULT_SENSITIVE_PATTERNS = [
        /password/i,
        /secret/i,
        /token/i,
        /api_key/i,
        /private_key/i
      ].freeze

      COMMON_REQUIRED_VARS = %w[
        RAILS_ENV
        SECRET_KEY_BASE
        DATABASE_URL
      ].freeze

      def initialize(options = {})
        @app_path = options[:app_path] || Dir.pwd
        @required_vars = options[:required_vars] || COMMON_REQUIRED_VARS
        @warn_on_defaults = options.fetch(:warn_on_defaults, true)
        @result = Result.new("Environment Variables")
      end

      def run
        check_required_vars_present
        check_no_default_placeholder_values
        check_no_sensitive_vars_in_env_file
        result
      end

      private

      def check_required_vars_present
        missing = @required_vars.reject { |var| ENV.key?(var) }
        if missing.empty?
          result.add_info("All required environment variables are present")
        else
          missing.each do |var|
            result.add_error("Required environment variable missing: #{var}")
          end
        end
      end

      def check_no_default_placeholder_values
        return unless @warn_on_defaults

        placeholder_pattern = /\A(changeme|placeholder|your[_-]?.*here|todo|fixme|replace.?me)\z/i
        ENV.each do |key, value|
          if value.match?(placeholder_pattern)
            result.add_warning("Environment variable #{key} appears to have a placeholder value")
          end
        end
      end

      def check_no_sensitive_vars_in_env_file
        env_file = File.join(@app_path, ".env")
        return unless File.exist?(env_file)

        sensitive_found = []
        File.readlines(env_file).each_with_index do |line, idx|
          next if line.strip.start_with?("#") || line.strip.empty?

          key = line.split("=").first.to_s.strip
          if DEFAULT_SENSITIVE_PATTERNS.any? { |pat| key.match?(pat) }
            sensitive_found << "line #{idx + 1}: #{key}"
          end
        end

        if sensitive_found.any?
          result.add_warning("Sensitive keys found in .env file (ensure it is not committed): #{sensitive_found.join(", ")}")
        else
          result.add_info(".env file exists and contains no obviously sensitive keys at risk")
        end
      end
    end
  end
end
