module RailsDeployCheck
  module Checks
    class CdnCheck
      attr_reader :result

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @cdn_url   = options[:cdn_url] || ENV["CDN_URL"] || ENV["ASSET_HOST"]
        @result    = Result.new("CDN")
      end

      def run
        check_cdn_url_configured
        check_cdn_url_format
        check_asset_host_in_config
        result
      end

      private

      def check_cdn_url_configured
        if @cdn_url.nil? || @cdn_url.strip.empty?
          result.add_warning("No CDN URL configured (CDN_URL or ASSET_HOST env var). Assets will be served from the app server.")
        else
          result.add_info("CDN URL configured: #{@cdn_url}")
        end
      end

      def check_cdn_url_format
        return if @cdn_url.nil? || @cdn_url.strip.empty?

        unless @cdn_url.match?(%r{\Ahttps?://})
          result.add_error("CDN URL '#{@cdn_url}' does not start with http:// or https://")
        end

        if @cdn_url.end_with?("/")
          result.add_warning("CDN URL '#{@cdn_url}' has a trailing slash, which may cause double-slash asset paths.")
        end
      end

      def check_asset_host_in_config
        config_files = [
          File.join(@app_path, "config", "environments", "production.rb"),
          File.join(@app_path, "config", "application.rb")
        ]

        found = config_files.any? do |path|
          File.exist?(path) && File.read(path).include?("asset_host")
        end

        if found
          result.add_info("asset_host is referenced in Rails config.")
        else
          result.add_warning("No asset_host setting found in config/environments/production.rb or config/application.rb.")
        end
      end
    end
  end
end
