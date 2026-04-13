# frozen_string_literal: true

require "socket"
require "timeout"

module RailsDeployCheck
  module Checks
    class NetworkCheck
      DEFAULT_TIMEOUT = 5
      WELL_KNOWN_HOSTS = [
        { host: "8.8.8.8", port: 53, label: "DNS (Google)" },
        { host: "1.1.1.1", port: 53, label: "DNS (Cloudflare)" }
      ].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @timeout  = options.fetch(:timeout, DEFAULT_TIMEOUT)
        @hosts    = options.fetch(:hosts, [])
        @result   = Result.new("NetworkCheck")
      end

      def run
        check_external_connectivity
        check_custom_hosts
        @result
      end

      private

      def check_external_connectivity
        reachable = WELL_KNOWN_HOSTS.any? do |entry|
          host_reachable?(entry[:host], entry[:port])
        end

        if reachable
          @result.add_info("External network connectivity confirmed")
        else
          @result.add_error("No external network connectivity detected — deployment may fail")
        end
      end

      def check_custom_hosts
        return if @hosts.empty?

        @hosts.each do |entry|
          host = entry[:host]
          port = entry.fetch(:port, 80)
          label = entry.fetch(:label, "#{host}:#{port}")

          if host_reachable?(host, port)
            @result.add_info("Custom host reachable: #{label}")
          else
            @result.add_warning("Custom host unreachable: #{label} (#{host}:#{port})")
          end
        end
      end

      def host_reachable?(host, port)
        Timeout.timeout(@timeout) do
          TCPSocket.new(host, port).close
          true
        end
      rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
             Errno::ENETUNREACH, SocketError
        false
      end
    end
  end
end
