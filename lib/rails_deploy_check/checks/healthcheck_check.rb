module RailsDeployCheck
  module Checks
    class HealthcheckCheck
      DEFAULT_PATHS = ["/healthz", "/health", "/up", "/ping"].freeze
      DEFAULT_TIMEOUT = 5

      def initialize(config = {})
        @app_root   = config.fetch(:app_root, Dir.pwd)
        @host       = config[:host]
        @port       = config.fetch(:port, 3000)
        @paths      = config.fetch(:paths, DEFAULT_PATHS)
        @timeout    = config.fetch(:timeout, DEFAULT_TIMEOUT)
        @require_ok = config.fetch(:require_ok, false)
      end

      def run
        result = Result.new("Healthcheck")

        check_healthcheck_route_defined(result)
        check_healthcheck_reachable(result) if @host

        result
      end

      private

      def check_healthcheck_route_defined(result)
        routes_file = File.join(@app_root, "config", "routes.rb")

        unless File.exist?(routes_file)
          result.add_warning("config/routes.rb not found; cannot verify healthcheck route")
          return
        end

        content = File.read(routes_file)
        matched_path = @paths.find { |p| content.include?(p.delete_prefix("/")) }

        if matched_path
          result.add_info("Healthcheck route detected (#{matched_path}) in config/routes.rb")
        else
          result.add_warning(
            "No healthcheck route found in config/routes.rb. " \
            "Consider adding one of: #{@paths.join(', ')}"
          )
        end
      end

      def check_healthcheck_reachable(result)
        require "net/http"
        require "uri"

        @paths.each do |path|
          uri = URI::HTTP.build(host: @host, port: @port, path: path)
          response = Net::HTTP.start(uri.host, uri.port, open_timeout: @timeout, read_timeout: @timeout) do |http|
            http.get(uri.path)
          end

          code = response.code.to_i
          if code < 500
            result.add_info("Healthcheck endpoint #{path} responded with HTTP #{code}")
            return
          else
            msg = "Healthcheck endpoint #{path} returned HTTP #{code}"
            @require_ok ? result.add_error(msg) : result.add_warning(msg)
          end
        rescue => e
          result.add_warning("Could not reach healthcheck endpoint #{path}: #{e.message}")
        end
      end
    end
  end
end
