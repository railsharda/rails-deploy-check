# frozen_string_literal: true

require "openssl"
require "socket"
require "timeout"

module RailsDeployCheck
  module Checks
    class SslExpiryCheck
      DEFAULT_WARNING_DAYS = 30
      DEFAULT_CRITICAL_DAYS = 7
      DEFAULT_TIMEOUT = 10

      def initialize(host:, port: 443, warning_days: DEFAULT_WARNING_DAYS, critical_days: DEFAULT_CRITICAL_DAYS, timeout: DEFAULT_TIMEOUT)
        @host = host
        @port = port
        @warning_days = warning_days
        @critical_days = critical_days
        @timeout = timeout
      end

      def run
        result = Result.new("SSL Expiry")

        if @host.nil? || @host.strip.empty?
          result.add_error("No host configured for SSL expiry check")
          return result
        end

        check_certificate_expiry(result)
        result
      end

      private

      def check_certificate_expiry(result)
        cert = fetch_certificate
        if cert.nil?
          result.add_warning("Could not retrieve SSL certificate from #{@host}:#{@port}")
          return
        end

        expiry = cert.not_after
        days_remaining = ((expiry - Time.now) / 86_400).to_i

        if days_remaining < 0
          result.add_error("SSL certificate for #{@host} has expired (expired #{days_remaining.abs} days ago on #{expiry.strftime('%Y-%m-%d')})") 
        elsif days_remaining <= @critical_days
          result.add_error("SSL certificate for #{@host} expires in #{days_remaining} days (#{expiry.strftime('%Y-%m-%d')}) — critical threshold is #{@critical_days} days")
        elsif days_remaining <= @warning_days
          result.add_warning("SSL certificate for #{@host} expires in #{days_remaining} days (#{expiry.strftime('%Y-%m-%d')}) — consider renewing soon")
        else
          result.add_info("SSL certificate for #{@host} is valid for #{days_remaining} more days (expires #{expiry.strftime('%Y-%m-%d')})")
        end
      rescue => e
        result.add_warning("SSL expiry check failed for #{@host}: #{e.message}")
      end

      def fetch_certificate
        Timeout.timeout(@timeout) do
          tcp = TCPSocket.new(@host, @port)
          ctx = OpenSSL::SSL::SSLContext.new
          ssl = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
          ssl.hostname = @host
          ssl.connect
          cert = ssl.peer_cert
          ssl.close
          tcp.close
          cert
        end
      rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
        nil
      end
    end
  end
end
