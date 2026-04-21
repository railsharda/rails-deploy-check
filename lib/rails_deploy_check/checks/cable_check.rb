module RailsDeployCheck
  module Checks
    class CableCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @cable_yml_path = options[:cable_yml_path]
        @adapter = options[:adapter]
      end

      def run
        result = Result.new(name: "Action Cable")

        check_cable_yml_exists(result)
        check_adapter_configured(result)
        check_adapter_known(result)
        check_async_not_in_production(result)

        result
      end

      private

      def cable_yml_path
        @cable_yml_path || File.join(@app_path, "config", "cable.yml")
      end

      def cable_yml_content
        @cable_yml_content ||= File.read(cable_yml_path) if File.exist?(cable_yml_path)
      end

      def check_cable_yml_exists(result)
        if File.exist?(cable_yml_path)
          result.add_info("config/cable.yml found")
        else
          result.add_warning("config/cable.yml not found — Action Cable may not be configured")
        end
      end

      def check_adapter_configured(result)
        return unless cable_yml_content

        if cable_yml_content.match?(/adapter:/)
          result.add_info("Action Cable adapter is configured")
        else
          result.add_warning("No adapter configured in config/cable.yml")
        end
      end

      def check_adapter_known(result)
        return unless cable_yml_content

        adapter = @adapter || ENV["ACTION_CABLE_ADAPTER"]
        detected = cable_yml_content.match(/adapter:\s*([\w]+)/)
        detected_adapter = adapter || (detected && detected[1])

        return unless detected_adapter

        known_adapters = %w[async redis postgresql solid_cable]
        if known_adapters.include?(detected_adapter.downcase)
          result.add_info("Action Cable adapter '#{detected_adapter}' is a known adapter")
        else
          result.add_warning("Action Cable adapter '#{detected_adapter}' is not a commonly used adapter")
        end
      end

      def check_async_not_in_production(result)
        return unless cable_yml_content

        rails_env = ENV["RAILS_ENV"] || "development"
        return unless rails_env == "production"

        if cable_yml_content.match?(/adapter:\s*async/)
          result.add_error("Action Cable is using 'async' adapter in production — use Redis or PostgreSQL instead")
        end
      end
    end
  end
end
