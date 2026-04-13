require 'uri'
require 'net/http'
require_relative 'api_health_check'

module RailsDeployCheck
  module Checks
    class ApiHealthCheckIntegration
      class << self
        def build(options = {})
          url = options[:url] || detect_url
          ApiHealthCheck.new(options.merge(url: url))
        end

        def register(runner)
          return unless applicable?

          runner.register(:api_health, build)
        end

        def applicable?
          api_health_url_present? || api_base_url_present?
        end

        def detect_url
          return ENV['API_HEALTH_URL'] if ENV['API_HEALTH_URL'] && !ENV['API_HEALTH_URL'].empty?

          if ENV['API_BASE_URL'] && !ENV['API_BASE_URL'].empty?
            base = ENV['API_BASE_URL'].chomp('/')
            return "#{base}/health"
          end

          nil
        end

        private

        def api_health_url_present?
          ENV.key?('API_HEALTH_URL') && !ENV['API_HEALTH_URL'].to_s.strip.empty?
        end

        def api_base_url_present?
          ENV.key?('API_BASE_URL') && !ENV['API_BASE_URL'].to_s.strip.empty?
        end
      end
    end
  end
end
