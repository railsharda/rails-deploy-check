# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class PrometheusCheck
      KNOWN_PORTS = [9090, 9091, 9093].freeze
      DEFAULT_METRICS_PATH = "/metrics".freeze

      def initialize(options = {})
        @app_root = options.fetch(:app_root, Dir.pwd)
        @metrics_url = options[:metrics_url] || ENV["PROMETHEUS_METRICS_URL"]
        @pushgateway_url = options[:pushgateway_url] || ENV["PROMETHEUS_PUSHGATEWAY_URL"]
        @required_metrics = options.fetch(:required_metrics, [])
      end

      def run
        result = Result.new("Prometheus")

        check_gem_in_lockfile(result)
        check_metrics_url_configured(result)
        check_pushgateway_url_format(result)
        check_initializer_exists(result)

        result
      end

      private

      def check_gem_in_lockfile(result)
        lockfile = File.join(@app_root, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found; cannot verify prometheus gem")
          return
        end

        content = File.read(lockfile)
        if content.include?("prometheus-client") || content.include?("yabeda")
          result.add_info("Prometheus client gem found in Gemfile.lock")
        else
          result.add_warning("No prometheus-client or yabeda gem found in Gemfile.lock")
        end
      end

      def check_metrics_url_configured(result)
        if @metrics_url.nil? || @metrics_url.strip.empty?
          result.add_warning("PROMETHEUS_METRICS_URL is not set; metrics endpoint may not be configured")
          return
        end

        begin
          uri = URI.parse(@metrics_url)
          unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            result.add_error("PROMETHEUS_METRICS_URL does not appear to be a valid HTTP(S) URL: #{@metrics_url}")
            return
          end
          unless uri.path.include?(DEFAULT_METRICS_PATH) || uri.path.end_with?("/metrics")
            result.add_warning("PROMETHEUS_METRICS_URL path does not include '/metrics': #{uri.path}")
          end
          result.add_info("Prometheus metrics URL configured: #{@metrics_url}")
        rescue URI::InvalidURIError
          result.add_error("PROMETHEUS_METRICS_URL is not a valid URI: #{@metrics_url}")
        end
      end

      def check_pushgateway_url_format(result)
        return if @pushgateway_url.nil? || @pushgateway_url.strip.empty?

        begin
          uri = URI.parse(@pushgateway_url)
          unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            result.add_error("PROMETHEUS_PUSHGATEWAY_URL is not a valid HTTP(S) URL"
          unless KNOWN_PORTS.include?(uri.port)
            result.add_warning("PROMETHEUS_PUSHGATEWAY_URL uses non-standard port #{uri.port} (expected: #{KNOWN_PORTS.join(", ")})")
          end
          result.add_info("Prometheus Pushgateway URL configured: #{@pushgateway_url}")
        rescue URI::InvalidURIError
          result.add_error("PROMETHEUS_PUSHGATEWAY_URL is not a valid URI: #{@pushgateway_url}")
        end
      end

      def check_initializer_exists(result)
        initializer_paths = [
          File.join(@app_root, "config", "initializers", "prometheus.rb"),
          File.join(@app_root, "config", "initializers", "yabeda.rb"),
          File.join(@app_root, "config", "initializers", "metrics.rb")
        ]

        found = initializer_paths.any? { |p| File.exist?(p) }
        if found
          result.add_info("Prometheus initializer file found")
        else
          result.add_warning("No Prometheus initializer found in config/initializers/")
        end
      end
    end
  end
end
