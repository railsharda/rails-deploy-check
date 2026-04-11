# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class QueueCheck
      KNOWN_QUEUE_ADAPTERS = %w[sidekiq resque delayed_job good_job que async inline test].freeze
      DEFAULT_ADAPTER = "async"

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @warn_on_async = options.fetch(:warn_on_async, true)
        @warn_on_inline = options.fetch(:warn_on_inline, true)
      end

      def run
        result = Result.new(name: "Queue")
        check_queue_adapter_configured(result)
        check_queue_adapter_known(result)
        check_adapter_production_suitability(result)
        result
      end

      private

      def check_queue_adapter_configured(result)
        adapter = detected_adapter
        if adapter
          result.add_info("Queue adapter detected: #{adapter}")
        else
          result.add_warning("No queue adapter explicitly configured; Rails will use default (#{DEFAULT_ADAPTER})")
        end
      end

      def check_queue_adapter_known(result)
        adapter = detected_adapter
        return unless adapter

        unless KNOWN_QUEUE_ADAPTERS.include?(adapter.downcase)
          result.add_warning("Unknown queue adapter '#{adapter}'; ensure it is properly configured")
        end
      end

      def check_adapter_production_suitability(result)
        adapter = (detected_adapter || DEFAULT_ADAPTER).downcase

        if adapter == "async" && @warn_on_async
          result.add_warning(
            "Queue adapter is '#{adapter}', which does not persist jobs across restarts. " \
            "Consider using a persistent adapter (e.g. sidekiq, good_job) for production."
          )
        end

        if adapter == "inline" && @warn_on_inline
          result.add_warning(
            "Queue adapter is 'inline', which processes jobs synchronously. " \
            "This may cause slow requests in production."
          )
        end
      end

      def detected_adapter
        @detected_adapter ||= detect_from_environment || detect_from_application_config
      end

      def detect_from_environment
        val = ENV["QUEUE_ADAPTER"] || ENV["ACTIVE_JOB_QUEUE_ADAPTER"]
        val&.strip&.downcase
      end

      def detect_from_application_config
        config_file = File.join(@app_path, "config", "application.rb")
        return nil unless File.exist?(config_file)

        content = File.read(config_file)
        match = content.match(/config\.active_job\.queue_adapter\s*=\s*[:'"](\w+)/)
        match&.[](1)&.downcase
      end
    end
  end
end
