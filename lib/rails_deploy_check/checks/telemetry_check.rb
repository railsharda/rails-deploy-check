# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class TelemetryCheck
      KNOWN_PROVIDERS = %w[
        DATADOG_API_KEY
        DD_API_KEY
        HONEYBADGER_API_KEY
        SKYLIGHT_AUTHENTICATION
        SCOUT_KEY
        APPSIGNAL_PUSH_API_KEY
        ELASTIC_APM_SECRET_TOKEN
      ].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @required_provider = options[:required_provider]
        @warn_if_missing = options.fetch(:warn_if_missing, true)
      end

      def run
        result = Result.new(name: "Telemetry")
        check_provider_configured(result)
        check_initializer_exists(result)
        result
      end

      private

      def check_provider_configured(result)
        if @required_provider
          key = @required_provider.to_s.upcase
          if ENV[key].nil? || ENV[key].strip.empty?
            result.add_error("Required telemetry provider key '#{key}' is not set")
          else
            result.add_info("Telemetry provider key '#{key}' is configured")
          end
          return
        end

        detected = KNOWN_PROVIDERS.select { |key| ENV[key] && !ENV[key].strip.empty? }

        if detected.any?
          result.add_info("Telemetry provider(s) detected: #{detected.join(', ')}")
        elsif @warn_if_missing
          result.add_warning(
            "No telemetry/APM provider detected. Consider configuring one of: " \
            "#{KNOWN_PROVIDERS.first(4).join(', ')}, etc."
          )
        end
      end

      def check_initializer_exists(result)
        initializer_dir = File.join(@app_path, "config", "initializers")
        return unless Dir.exist?(initializer_dir)

        telemetry_initializers = Dir.glob(File.join(initializer_dir, "*.rb")).select do |f|
          basename = File.basename(f)
          basename.match?(/datadog|appsignal|skylight|honeybadger|scout|elastic_apm/i)
        end

        if telemetry_initializers.any?
          names = telemetry_initializers.map { |f| File.basename(f) }.join(", ")
          result.add_info("Telemetry initializer(s) found: #{names}")
        else
          result.add_warning("No telemetry initializer found in config/initializers/")
        end
      end
    end
  end
end
