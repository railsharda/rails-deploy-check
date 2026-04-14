# frozen_string_literal: true

require "openssl"
require "socket"

module RailsDeployCheck
  module Checks
    class TlsVersionCheck
      MINIMUM_TLS_VERSION = "TLSv1_2"
      DEPRECATED_VERSIONS = %w[TLSv1 TLSv1_1 SSLv3 SSLv2].freeze
      KNOWN_PORTS = { 443 => "HTTPS", 465 => "SMTPS", 993 => "IMAPS", 995 => "POP3S" }.freeze

      def initialize(host: nil, port: 443, warn_on_tls12: false, app_path: Dir.pwd)
        @host = host || ENV["SSL_HOST"] || ENV["APP_HOST"]
        @port = port.to_i
        @warn_on_tls12 = warn_on_tls12
        @app_path = app_path
      end

      def run
        result = Result.new(name: "TLS Version")

        if @host.nil? || @host.strip.empty?
          result.add_info("No host configured for TLS version check; skipping")
          return result
        end

        check_minimum_tls_version(result)
        check_deprecated_protocols(result)
        check_tls13_support(result)

        result
      end

      private

      def check_minimum_tls_version(result)
        context = build_ssl_context(min_version: OpenSSL::SSL::TLS1_2_VERSION)
        connected = attempt_connection(context)

        if connected
          result.add_info("TLS 1.2+ is supported on #{@host}:#{@port}")
        else
          result.add_error("Could not establish TLS 1.2 connection to #{@host}:#{@port}")
        end
      rescue => e
        result.add_warning("TLS version check failed for #{@host}:#{@port}: #{e.message}")
      end

      def check_deprecated_protocols(result)
        DEPRECATED_VERSIONS.each do |version|
          constant = OpenSSL::SSL.const_get("#{version.upcase.tr('.', '_')}_VERSION") rescue nil
          next unless constant

          context = build_ssl_context(max_version: constant, min_version: constant)
          if attempt_connection(context)
            result.add_error("Deprecated protocol #{version} is accepted on #{@host}:#{@port}")
          end
        end
      rescue => e
        result.add_info("Could not probe deprecated protocols: #{e.message}")
      end

      def check_tls13_support(result)
        tls13_const = OpenSSL::SSL::TLS1_3_VERSION rescue nil
        return result.add_info("OpenSSL version does not support TLS 1.3 detection") unless tls13_const

        context = build_ssl_context(min_version: tls13_const)
        if attempt_connection(context)
          result.add_info("TLS 1.3 is supported on #{@host}:#{@port}")
        elsif @warn_on_tls12
          result.add_warning("TLS 1.3 is not available on #{@host}:#{@port}; consider upgrading")
        else
          result.add_info("TLS 1.3 not detected on #{@host}:#{@port}")
        end
      rescue => e
        result.add_info("TLS 1.3 probe skipped: #{e.message}")
      end

      def build_ssl_context(min_version: nil, max_version: nil)
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.min_version = min_version if min_version
        ctx.max_version = max_version if max_version
        ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
        ctx
      end

      def attempt_connection(context)
        tcp = Socket.tcp(@host, @port, connect_timeout: 5)
        ssl = OpenSSL::SSL::SSLSocket.new(tcp, context)
        ssl.hostname = @host
        ssl.connect
        ssl.close
        tcp.close
        true
      rescue
        false
      end
    end
  end
end
