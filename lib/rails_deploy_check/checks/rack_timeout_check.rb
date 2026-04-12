# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class RackTimeoutCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @warn_timeout = options.fetch(:warn_timeout, 5)
        @service_timeout = options.fetch(:service_timeout, 15)
      end

      def run
        result = Result.new(name: "Rack Timeout")
        check_gem_in_lockfile(result)
        check_initializer_exists(result)
        check_timeout_values(result)
        result
      end

      private

      def check_gem_in_lockfile(result)
        if rack_timeout_in_lockfile?
          result.add_info("rack-timeout gem found in Gemfile.lock")
        else
          result.add_warning("rack-timeout gem not found in Gemfile.lock; consider adding it to prevent hung requests")
        end
      end

      def check_initializer_exists(result)
        initializer = File.join(@app_path, "config", "initializers", "timeout.rb")
        rack_timeout_init = File.join(@app_path, "config", "initializers", "rack_timeout.rb")

        if File.exist?(initializer) || File.exist?(rack_timeout_init)
          result.add_info("Rack timeout initializer found")
        else
          result.add_warning("No rack-timeout initializer found; default timeouts may apply")
        end
      end

      def check_timeout_values(result)
        env_service = ENV["RACK_TIMEOUT_SERVICE_TIMEOUT"]
        env_warn = ENV["RACK_TIMEOUT_WAIT_TIMEOUT"]

        if env_service
          val = env_service.to_i
          if val <= 0
            result.add_error("RACK_TIMEOUT_SERVICE_TIMEOUT is set to an invalid value: #{env_service}")
          elsif val < @warn_timeout
            result.add_warning("RACK_TIMEOUT_SERVICE_TIMEOUT (#{val}s) is very low; may cause premature timeouts")
          else
            result.add_info("RACK_TIMEOUT_SERVICE_TIMEOUT is set to #{val}s")
          end
        else
          result.add_info("RACK_TIMEOUT_SERVICE_TIMEOUT not set; using gem or Rails defaults")
        end

        if env_warn && env_warn.to_i > 0 && env_service && env_warn.to_i >= env_service.to_i
          result.add_warning("RACK_TIMEOUT_WAIT_TIMEOUT (#{env_warn}s) should be less than service timeout (#{env_service}s)")
        end
      end

      def rack_timeout_in_lockfile?
        lockfile = File.join(@app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).include?("rack-timeout")
      end
    end
  end
end
