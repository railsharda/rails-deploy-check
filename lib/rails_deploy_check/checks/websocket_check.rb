# frozen_string_literal: true

require "uri"
require "socket"

module RailsDeployCheck
  module Checks
    class WebsocketCheck
      attr_reader :result

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @ws_url = options[:ws_url] || ENV["WEBSOCKET_URL"]
        @action_cable_url = options[:action_cable_url] || ENV["ACTION_CABLE_URL"]
        @result = Result.new("WebSocket / Action Cable")
      end

      def run
        check_action_cable_config_exists
        check_cable_yml_configured
        check_websocket_url_format if @ws_url || @action_cable_url
        result
      end

      private

      def check_action_cable_config_exists
        cable_yml = File.join(@app_path, "config", "cable.yml")
        unless File.exist?(cable_yml)
          result.add_warning("config/cable.yml not found — Action Cable may not be configured")
          return
        end
        result.add_info("config/cable.yml found")
      end

      def check_cable_yml_configured
        cable_yml = File.join(@app_path, "config", "cable.yml")
        return unless File.exist?(cable_yml)

        content = File.read(cable_yml)
        rails_env = ENV.fetch("RAILS_ENV", "production")

        unless content.include?(rails_env)
          result.add_warning("config/cable.yml does not appear to have a '#{rails_env}' section")
          return
        end

        if content.match?(/adapter:\s*async/)
          result.add_warning("Action Cable is using the 'async' adapter — not suitable for production")
        elsif content.match?(/adapter:\s*redis/)
          result.add_info("Action Cable is configured to use the Redis adapter")
        else
          result.add_info("Action Cable adapter configured in cable.yml")
        end
      end

      def check_websocket_url_format
        url_to_check = @ws_url || @action_cable_url
        begin
          uri = URI.parse(url_to_check)
          unless %w[ws wss http https].include?(uri.scheme)
            result.add_error("WebSocket URL '#{url_to_check}' has an unsupported scheme '#{uri.scheme}'")
            return
          end
          if uri.scheme == "ws"
            result.add_warning("WebSocket URL uses insecure 'ws://' scheme — consider using 'wss://'")
          else
            result.add_info("WebSocket URL scheme is acceptable: #{uri.scheme}")
          end
        rescue URI::InvalidURIError
          result.add_error("WebSocket URL '#{url_to_check}' is not a valid URI")
        end
      end
    end
  end
end
