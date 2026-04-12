# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class RackAttackCheck
      attr_reader :result

      def initialize(app_path: Dir.pwd, env: ENV)
        @app_path = app_path
        @env = env
        @result = Result.new(name: "Rack::Attack")
      end

      def run
        check_gem_in_lockfile
        check_initializer_exists
        check_cache_store_configured
        check_throttle_env_variables
        result
      end

      private

      def check_gem_in_lockfile
        if rack_attack_in_lockfile?
          result.add_info("rack-attack gem found in Gemfile.lock")
        else
          result.add_warning("rack-attack gem not found in Gemfile.lock — rate limiting may not be configured")
        end
      end

      def check_initializer_exists
        return unless rack_attack_in_lockfile?

        initializer = File.join(@app_path, "config", "initializers", "rack_attack.rb")
        if File.exist?(initializer)
          result.add_info("Rack::Attack initializer found at config/initializers/rack_attack.rb")
        else
          result.add_warning("rack-attack gem present but no initializer found at config/initializers/rack_attack.rb")
        end
      end

      def check_cache_store_configured
        return unless rack_attack_in_lockfile?

        cache_url = @env["RACK_ATTACK_CACHE_URL"] || @env["REDIS_URL"] || @env["MEMCACHE_SERVERS"]
        if cache_url
          result.add_info("Cache store environment variable configured for Rack::Attack")
        else
          result.add_warning(
            "No cache store URL found (RACK_ATTACK_CACHE_URL, REDIS_URL, or MEMCACHE_SERVERS) — " \
            "Rack::Attack requires a shared cache store in production"
          )
        end
      end

      def check_throttle_env_variables
        return unless rack_attack_in_lockfile?

        throttle_limit = @env["RACK_ATTACK_THROTTLE_LIMIT"]
        throttle_period = @env["RACK_ATTACK_THROTTLE_PERIOD"]

        if throttle_limit && throttle_period
          result.add_info("Rack::Attack throttle env variables configured (limit=#{throttle_limit}, period=#{throttle_period}s)")
        else
          result.add_info("Rack::Attack throttle limits not set via environment variables (may be hardcoded in initializer)")
        end
      end

      def rack_attack_in_lockfile?
        @rack_attack_in_lockfile ||= begin
          lockfile = File.join(@app_path, "Gemfile.lock")
          File.exist?(lockfile) && File.read(lockfile).match?(/rack-attack/)
        end
      end
    end
  end
end
