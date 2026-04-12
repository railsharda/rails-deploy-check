# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module ExternalServicesCheckIntegration
      class << self
        def build(options = {})
          required_services = options.fetch(:required_services, detect_required_services)
          ExternalServicesCheck.new(
            app_path: options.fetch(:app_path, Dir.pwd),
            required_services: required_services,
            check_reachability: options.fetch(:check_reachability, false)
          )
        end

        def register(runner)
          return unless applicable?

          runner.register(:external_services, build)
        end

        def applicable?
          any_known_service_env_present? || required_services_configured?
        end

        def any_known_service_env_present?
          ExternalServicesCheck::KNOWN_SERVICES.keys.any? do |key|
            value = ENV[key]
            value && !value.strip.empty?
          end
        end

        def required_services_configured?
          detect_required_services.any?
        end

        private

        def detect_required_services
          env_value = ENV["REQUIRED_EXTERNAL_SERVICES"]
          return [] if env_value.nil? || env_value.strip.empty?

          env_value.split(",").map(&:strip).reject(&:empty?)
        end
      end
    end
  end
end
