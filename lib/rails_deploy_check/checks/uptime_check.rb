# frozen_string_literal: true

require "net/http"
require "uri"

module RailsDeployCheck
  module Checks
    class UptimeCheck
      DEFAULT_TIMEOUT = 10
      SUCCESS_CODES = (200..399).freeze

      def initialize(options = {})
        @url = options[:url] || ENV["UPTIME_CHECK_URL"]
        @timeout = options[:timeout] || DEFAULT_TIMEOUT
        @expected_status = options[:expected_status]
      end

      def run
        result = Result.new("Uptime Check")

        check_url_configured(result)
        check_endpoint_reachable(result) if result.errors.empty?

        result
      end

      private

      def check_url_configured(result)
        if @url.nil? || @url.strip.empty?
          result.add_warning("No uptime check URL configured (set UPTIME_CHECK_URL or pass :url option)")
        else
          begin
            URI.parse(@url)
            result.add_info("Uptime check URL configured: #{@url}")
          rescue URI::InvalidURIError
            result.add_error("Uptime check URL is invalid: #{@url}")
          end
        end
      end

      def check_endpoint_reachable(result)
        uri = URI.parse(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @timeout
        http.read_timeout = @timeout

        response = http.get(uri.request_uri.empty? ? "/" : uri.request_uri)
        status = response.code.to_i

        if @expected_status
          if status == @expected_status
            result.add_info("Endpoint responded with expected status #{status}")
          else
            result.add_error("Endpoint responded with #{status}, expected #{@expected_status}")
          end
        elsif SUCCESS_CODES.include?(status)
          result.add_info("Endpoint is reachable (HTTP #{status})")
        else
          result.add_error("Endpoint returned non-success status: HTTP #{status}")
        end
      rescue Net::OpenTimeout, Net::ReadTimeout
        result.add_error("Endpoint timed out after #{@timeout}s: #{@url}")
      rescue SocketError => e
        result.add_error("Could not reach endpoint: #{e.message}")
      rescue => e
        result.add_error("Unexpected error checking uptime: #{e.message}")
      end
    end
  end
end
