# frozen_string_literal: true

require "uri"

module RailsDeployCheck
  module Checks
    class RedisCheck
      DEFAULT_URL = "redis://localhost:6379"
      TIMEOUT = 2

      def initialize(config = {})
        @url = config.fetch(:url) { ENV["REDIS_URL"] || DEFAULT_URL }
        @required = config.fetch(:required, false)
      end

      def run
        result = Result.new(name: "Redis")

        check_redis_gem_available(result)
        check_redis_url_format(result)
        check_redis_connection(result)

        result
      end

      private

      def check_redis_gem_available(result)
        require "redis"
        result.add_info("Redis gem is available")
      rescue LoadError
        if @required
          result.add_error("Redis gem is not available. Add 'redis' to your Gemfile")
        else
          result.add_warning("Redis gem not found — skipping connection check")
        end
      end

      def check_redis_url_format(result)
        uri = URI.parse(@url)
        unless %w[redis rediss].include?(uri.scheme)
          result.add_error("Invalid Redis URL scheme: #{uri.scheme.inspect}. Expected 'redis' or 'rediss'")
        end
      rescue URI::InvalidURIError
        result.add_error("Malformed Redis URL: #{@url.inspect}")
      end

      def check_redis_connection(result)
        return unless defined?(Redis)

        redis = Redis.new(url: @url, connect_timeout: TIMEOUT, timeout: TIMEOUT)
        redis.ping
        result.add_info("Redis connection successful (#{@url})")
      rescue Redis::CannotConnectError, Redis::ConnectionError => e
        if @required
          result.add_error("Cannot connect to Redis at #{@url}: #{e.message}")
        else
          result.add_warning("Cannot connect to Redis at #{@url}: #{e.message}")
        end
      rescue => e
        result.add_warning("Redis check encountered an unexpected error: #{e.message}")
      end
    end
  end
end
