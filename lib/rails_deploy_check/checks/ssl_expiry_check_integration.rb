# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module SslExpiryCheckIntegration
      def self.build(config = {})
        host = config[:host] || ENV["SSL_EXPIRY_HOST"] || ENV["APP_HOST"]
        return nil unless host

        SslExpiryCheck.new(
          host: host,
          warning_days: config[:warning_days] || 30,
          critical_days: config[:critical_days] || 7
        )
      end

      def self.register(registry)
        return unless applicable?

        check = build
        registry.register(check) if check
      end

      def self.applicable?
        ssl_host_present? || production_environment?
      end

      def self.ssl_host_present?
        ENV.key?("SSL_EXPIRY_HOST") || ENV.key?("APP_HOST")
      end

      def self.production_environment?
        ENV["RAILS_ENV"] == "production" || ENV["RACK_ENV"] == "production"
      end
    end
  end
end
