# frozen_string_literal: true

require "openssl"
require "socket"
require "timeout"

module RailsDeployCheck
  module Checks
    class SslCertificateCheck
      DEFAULT_WARN_DAYS = 30
      DEFAULT_ERROR_DAYS = 7
      DEFAULT_TIMEOUT = 10

      def initialize(options = {})
        @host = options[:host] || ENV["SSL_HOST"] || ENV["APP_HOST"]
        @port = (options[:port] || ENV["SSL_PORT"] || 443).to_i
        @warn_days = (options[:warn_days] || ENV["SSL_WARN_DAYS"] || DEFAULT_WARN_DAYS).to_i
        @error_days = (options[:error_days] || ENV["SSL_ERROR_DAYS"] || DEFAULT_ERROR_DAYS).to_i
        @timeout = (options[:timeout] || DEFAULT_TIMEOUT).to_i
      end

      def run
        result = Result.new("SSL Certificate")

        unless @host
          result.add_info("No SSL host configured, skipping certificate check")
          return result
        end

        check_certificate(result)
        result
      end

      private

      def check_certificate(result)
        cert = fetch_certificate(@host, @port)

        if cert.nil?
          result.add_error("Could not retrieve SSL certificate from #{@host}:#{@port}")
          return
        end

        check_expiry(result, cert)
        check_hostname(result, cert)
      rescue Timeout::Error
        result.add_error("Timed out connecting to #{@host}:#{@port} for SSL check")
      rescue OpenSSL::SSL::SSLError => e
        result.add_error("SSL error for #{@host}: #{e.message}")
      rescue SocketError => e
        result.add_error("Could not resolve host #{@host}: #{e.message}")
      end

      def check_expiry(result, cert)
        days_remaining = ((cert.not_after - Time.now) / 86_400).to_i

        if days_remaining <= @error_days
          result.add_error("SSL certificate for #{@host} expires in #{days_remaining} day(s) (expires #{cert.not_after})")
        elsif days_remaining <= @warn_days
          result.add_warning("SSL certificate for #{@host} expires in #{days_remaining} day(s) (expires #{cert.not_after})")
        else
          result.add_info("SSL certificate for #{@host} is valid for #{days_remaining} more day(s)")
        end
      end

      def check_hostname(result, cert)
        return if OpenSSL::SSL.verify_certificate_identity(cert, @host)

        result.add_error("SSL certificate hostname mismatch: certificate is not valid for #{@host}")
      end

      def fetch_certificate(host, port)
        Timeout.timeout(@timeout) do
          tcp = TCPSocket.new(host, port)
          ctx = OpenSSL::SSL::SSLContext.new
          ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
          ssl = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
          ssl.hostname = host
          ssl.connect
          cert = ssl.peer_cert
          ssl.close
          tcp.close
          cert
        end
      end
    end
  end
end
