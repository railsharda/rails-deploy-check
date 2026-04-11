# frozen_string_literal: true

require "socket"
require "timeout"

module RailsDeployCheck
  module Checks
    class SmtpCheck
      DEFAULT_TIMEOUT = 5
      KNOWN_PORTS = [25, 465, 587, 2525].freeze

      def initialize(config = {})
        @host = config[:host] || ENV["SMTP_HOST"]
        @port = (config[:port] || ENV["SMTP_PORT"] || 587).to_i
        @username = config[:username] || ENV["SMTP_USERNAME"]
        @timeout = config[:timeout] || DEFAULT_TIMEOUT
        @require_auth = config.fetch(:require_auth, true)
      end

      def run
        result = Result.new("SMTP")

        check_host_configured(result)
        check_port_known(result)
        check_smtp_reachable(result)
        check_auth_credentials(result) if @require_auth

        result
      end

      private

      def check_host_configured(result)
        if @host.nil? || @host.strip.empty?
          result.add_error("SMTP host is not configured (set SMTP_HOST or pass :host)")
        else
          result.add_info("SMTP host configured: #{@host}")
        end
      end

      def check_port_known(result)
        unless KNOWN_PORTS.include?(@port)
          result.add_warning("SMTP port #{@port} is not a commonly used port #{KNOWN_PORTS.inspect}")
        else
          result.add_info("SMTP port: #{@port}")
        end
      end

      def check_smtp_reachable(result)
        return if @host.nil? || @host.strip.empty?

        if port_reachable?(@host, @port)
          result.add_info("SMTP server #{@host}:#{@port} is reachable")
        else
          result.add_error("Cannot reach SMTP server at #{@host}:#{@port} (timeout: #{@timeout}s)")
        end
      rescue => e
        result.add_error("Error checking SMTP reachability: #{e.message}")
      end

      def check_auth_credentials(result)
        if @username.nil? || @username.strip.empty?
          result.add_warning("SMTP username not configured (set SMTP_USERNAME)")
        else
          result.add_info("SMTP username configured")
        end

        smtp_password = ENV["SMTP_PASSWORD"]
        if smtp_password.nil? || smtp_password.strip.empty?
          result.add_warning("SMTP password not configured (set SMTP_PASSWORD)")
        else
          result.add_info("SMTP password configured")
        end
      end

      def port_reachable?(host, port)
        Timeout.timeout(@timeout) do
          TCPSocket.new(host, port).close
          true
        end
      rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
        false
      end
    end
  end
end
