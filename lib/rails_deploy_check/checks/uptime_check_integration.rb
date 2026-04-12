# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module UptimeCheckIntegration
      UPTIME_ENV_VARS = %w[
        UPTIME_URL
        APP_URL
        HEALTHCHECK_URL
        RENDER_EXTERNAL_URL
        HEROKU_APP_DEFAULT_DOMAIN_NAME
      ].freeze

      def self.build(config = {})
        url = config[:url] || detect_url
        return nil unless url

        url = "https://#{url}" unless url.start_with?("http")

        UptimeCheck.new(
          url: url,
          timeout: config[:timeout] || 10
        )
      end

      def self.register(registry)
        return unless applicable?

        check = build
        registry.register(check) if check
      end

      def self.applicable?
        detect_url ? true : false
      end

      def self.detect_url
        UPTIME_ENV_VARS.each do |var|
          val = ENV[var]
          return val if val && !val.empty?
        end
        nil
      end
    end
  end
end
