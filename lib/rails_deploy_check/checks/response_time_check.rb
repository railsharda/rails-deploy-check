# frozen_string_literal: true

require "net/http"
require "uri"

module RailsDeployCheck
  module Checks
    class ResponseTimeCheck
      DEFAULT_THRESHOLD_MS = 2000
      DEFAULT_WARNING_MS   = 1000
      DEFAULT_TIMEOUT_S    = 10

      def initialize(options = {})
        @url              = options[:url] || ENV["HEALTH_CHECK_URL"] || ENV["APP_URL"]
        @threshold_ms     = options[:threshold_ms]   || DEFAULT_THRESHOLD_MS
        @warning_ms       = options[:warning_ms]     || DEFAULT_WARNING_MS
        @timeout_seconds  = options[:timeout_seconds] || DEFAULT_TIMEOUT_S
        @result           = Result.new("Response Time Check")
      end

      def run
        check_url_configured
        check_response_time if @url
        @result
      end

      private

      def check_url_configured
        if @url.nil? || @url.strip.empty?
          @result.add_warning("No URL configured for response time check. Set HEALTH_CHECK_URL or APP_URL.")
        else
          @result.add_info("Checking response time for: #{@url}")
        end
      end

      def check_response_time
        uri = URI.parse(@url)
        elapsed_ms = measure_response_time(uri)

        if elapsed_ms.nil?
          @result.add_error("Could not connect to #{@url} within #{@timeout_seconds}s timeout")
        elsif elapsed_ms > @threshold_ms
          @result.add_error(
            "Response time #{elapsed_ms}ms exceeds threshold of #{@threshold_ms}ms for #{@url}"
          )
        elsif elapsed_ms > @warning_ms
          @result.add_warning(
            "Response time #{elapsed_ms}ms is above warning threshold of #{@warning_ms}ms for #{@url}"
          )
        else
          @result.add_info("Response time #{elapsed_ms}ms is within acceptable range")
        end
      rescue URI::InvalidURIError
        @result.add_error("Invalid URL format: #{@url}")
      end

      def measure_response_time(uri)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @timeout_seconds
        http.read_timeout = @timeout_seconds
        http.get(uri.request_uri)
        finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        ((finish - start) * 1000).round
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout, SocketError
        nil
      end
    end
  end
end
