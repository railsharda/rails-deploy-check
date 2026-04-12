# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class RateLimitCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @check_throttle_config = options.fetch(:check_throttle_config, true)
      end

      def run
        result = Result.new(name: "Rate Limiting")

        check_rack_attack_or_throttle(result)
        check_throttle_initializer(result) if @check_throttle_config
        check_redis_for_throttle(result)

        result
      end

      private

      def check_rack_attack_or_throttle(result)
        has_rack_attack = gem_in_lockfile?("rack-attack")
        has_throttle = gem_in_lockfile?("rack-throttle")
        has_shield = gem_in_lockfile?("rack-shield")

        if has_rack_attack || has_throttle || has_shield
          gem_name = has_rack_attack ? "rack-attack" : (has_throttle ? "rack-throttle" : "rack-shield")
          result.add_info("Rate limiting gem detected: #{gem_name}")
        else
          result.add_warning(
            "No rate limiting gem found (rack-attack, rack-throttle, rack-shield). " \
            "Consider adding rate limiting to protect your application."
          )
        end
      end

      def check_throttle_initializer(result)
        initializer_paths = [
          File.join(@app_path, "config", "initializers", "rack_attack.rb"),
          File.join(@app_path, "config", "initializers", "throttle.rb"),
          File.join(@app_path, "config", "initializers", "rate_limit.rb")
        ]

        found = initializer_paths.find { |p| File.exist?(p) }

        if found
          result.add_info("Rate limiting initializer found: #{File.basename(found)}")
        elsif gem_in_lockfile?("rack-attack")
          result.add_warning(
            "rack-attack gem present but no initializer found. " \
            "Create config/initializers/rack_attack.rb to configure throttling rules."
          )
        end
      end

      def check_redis_for_throttle(result)
        return unless gem_in_lockfile?("rack-attack")

        redis_url = ENV["REDIS_URL"] || ENV["REDIS_TLS_URL"]
        unless redis_url
          result.add_warning(
            "rack-attack is present but no REDIS_URL detected. " \
            "Without Redis, rate limiting state is not shared across processes/servers."
          )
        end
      end

      def gem_in_lockfile?(gem_name)
        lockfile = File.join(@app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).match?(/^\s+#{Regexp.escape(gem_name)}\s/)
      end
    end
  end
end
