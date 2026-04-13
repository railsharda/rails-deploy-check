# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class ReadinessCheck
      READINESS_PATHS = [
        "/healthz",
        "/ready",
        "/readiness",
        "/_readiness"
      ].freeze

      def initialize(options = {})
        @app_url    = options[:app_url] || ENV["APP_URL"] || ENV["RAILS_APP_URL"]
        @timeout    = options[:timeout] || 5
        @expect_200 = options.fetch(:expect_200, true)
        @path       = options[:path]
      end

      def run
        result = Result.new("Readiness Check")

        if @app_url.nil? || @app_url.strip.empty?
          result.add_info("No APP_URL configured, skipping readiness probe")
          return result
        end

        check_readiness_endpoint(result)
        result
      end

      private

      def check_readiness_endpoint(result)
        probe_path = @path || detect_path
        if probe_path.nil?
          result.add_warning("No readiness endpoint path detected; set :path option or define a known readiness route")
          return
        end

        uri = build_uri(probe_path)
        response = perform_request(uri)

        if response.nil?
          result.add_error("Readiness endpoint #{uri} did not respond within #{@timeout}s")
        elsif @expect_200 && response.code.to_i != 200
          result.add_error("Readiness endpoint #{uri} returned HTTP #{response.code} (expected 200)")
        else
          result.add_info("Readiness endpoint #{uri} responded with HTTP #{response.code}")
        end
      rescue StandardError => e
        result.add_error("Readiness check failed: #{e.message}")
      end

      def detect_path
        READINESS_PATHS.first
      end

      def build_uri(path)
        base = @app_url.chomp("/")
        path = "/#{path}" unless path.start_with?("/")
        URI.parse("#{base}#{path}")
      end

      def perform_request(uri)
        require "net/http"
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @timeout
        http.read_timeout = @timeout
        http.get(uri.request_uri)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout, SocketError
        nil
      end
    end
  end
end
