# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class HttpsRedirectCheck
      attr_reader :result

      def initialize(options = {})
        @app_root = options.fetch(:app_root, Dir.pwd)
        @rails_env = options.fetch(:rails_env, ENV["RAILS_ENV"] || "production")
        @result = Result.new("HTTPS Redirect Check")
      end

      def run
        check_force_ssl_enabled
        check_no_http_asset_host
        result
      end

      private

      def check_force_ssl_enabled
        config_path = File.join(@app_root, "config", "environments", "#{@rails_env}.rb")

        unless File.exist?(config_path)
          result.add_warning("No #{@rails_env}.rb config found; cannot verify force_ssl setting")
          return
        end

        content = File.read(config_path)

        if content.match?(/config\.force_ssl\s*=\s*true/)
          result.add_info("force_ssl is enabled in #{@rails_env}.rb")
        elsif content.match?(/config\.force_ssl\s*=\s*false/)
          result.add_error("force_ssl is explicitly disabled in #{@rails_env}.rb")
        else
          result.add_warning("force_ssl not explicitly set in #{@rails_env}.rb; defaults to false in older Rails")
        end
      end

      def check_no_http_asset_host
        config_path = File.join(@app_root, "config", "environments", "#{@rails_env}.rb")
        return unless File.exist?(config_path)

        content = File.read(config_path)
        asset_host_match = content.match(/config\.action_controller\.asset_host\s*=\s*['"]([^'"]+)['"]/)

        return unless asset_host_match

        asset_host = asset_host_match[1]
        if asset_host.start_with?("http://")
          result.add_error("asset_host is configured with http:// — use https:// to avoid mixed content: #{asset_host}")
        else
          result.add_info("asset_host uses a secure scheme or is relative: #{asset_host}")
        end
      end
    end
  end
end
