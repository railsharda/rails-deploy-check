module RailsDeployCheck
  module Checks
    class ApiRateLimitCheck
      attr_reader :result, :options

      DEFAULT_PROVIDERS = %w[stripe twilio sendgrid github aws].freeze
      RATE_LIMIT_HEADERS = %w[
        X-RateLimit-Limit
        X-RateLimit-Remaining
        Retry-After
        X-Rate-Limit
      ].freeze

      def initialize(options = {})
        @options = options
        @result = Result.new("API Rate Limit Check")
        @app_path = options.fetch(:app_path, Dir.pwd)
      end

      def run
        check_rate_limit_gem_available
        check_api_clients_configured
        check_retry_logic_present
        check_exponential_backoff_hint
        result
      end

      private

      def check_rate_limit_gem_available
        lockfile = File.join(@app_path, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found; cannot verify rate-limit gems")
          return
        end

        content = File.read(lockfile)
        gems = %w[rack-attack throttle api-rate-limit]
        found = gems.select { |g| content.include?(g) }

        if found.any?
          result.add_info("Rate-limiting gem(s) detected: #{found.join(', ')}")
        else
          result.add_warning("No rate-limiting gem detected (rack-attack recommended for API protection)")
        end
      end

      def check_api_clients_configured
        initializers_path = File.join(@app_path, "config", "initializers")
        unless File.directory?(initializers_path)
          result.add_warning("No initializers directory found")
          return
        end

        api_initializers = Dir.glob(File.join(initializers_path, "*.rb")).select do |f|
          content = File.read(f)
          DEFAULT_PROVIDERS.any? { |p| content.downcase.include?(p) }
        end

        if api_initializers.any?
          result.add_info("API client initializer(s) found: #{api_initializers.map { |f| File.basename(f) }.join(', ')}")
        else
          result.add_info("No third-party API client initializers detected")
        end
      end

      def check_retry_logic_present
        retry_gems = %w[retriable retries stoplight]
        lockfile = File.join(@app_path, "Gemfile.lock")
        return unless File.exist?(lockfile)

        content = File.read(lockfile)
        found = retry_gems.select { |g| content.include?(g) }

        if found.any?
          result.add_info("Retry gem(s) present: #{found.join(', ')}")
        else
          result.add_warning("No retry gem detected; consider 'retriable' for handling API rate-limit errors gracefully")
        end
      end

      def check_exponential_backoff_hint
        env_val = ENV["API_RETRY_BACKOFF"] || ENV["RETRY_BACKOFF"]
        if env_val
          result.add_info("Exponential backoff env variable detected (#{env_val})")
        else
          result.add_info("Tip: set API_RETRY_BACKOFF env variable to configure retry delay strategy")
        end
      end
    end
  end
end
