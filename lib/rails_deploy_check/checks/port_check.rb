module RailsDeployCheck
  module Checks
    class PortCheck
      DEFAULT_PORTS = [80, 443].freeze

      def initialize(options = {})
        @ports = Array(options[:ports] || DEFAULT_PORTS)
        @host  = options[:host] || "127.0.0.1"
        @timeout = options[:timeout] || 5
      end

      def run
        result = Result.new("Port Check")

        if @ports.empty?
          result.add_info("No ports configured for checking")
          return result
        end

        @ports.each do |port|
          check_port(result, port)
        end

        result
      end

      private

      def check_port(result, port)
        unless valid_port?(port)
          result.add_error("Invalid port number: #{port} (must be 1-65535)")
          return
        end

        if port_open?(port)
          result.add_info("Port #{port} is open on #{@host}")
        else
          result.add_warning("Port #{port} is not reachable on #{@host}")
        end
      rescue => e
        result.add_error("Error checking port #{port}: #{e.message}")
      end

      def port_open?(port)
        require "socket"
        Timeout.timeout(@timeout) do
          TCPSocket.new(@host, port).close
          true
        end
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT,
             Timeout::Error, SocketError
        false
      end

      def valid_port?(port)
        port.is_a?(Integer) && port >= 1 && port <= 65_535
      end
    end
  end
end
