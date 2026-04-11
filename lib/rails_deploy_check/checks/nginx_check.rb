# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class NginxCheck
      attr_reader :result

      DEFAULT_CONFIG_PATHS = [
        "/etc/nginx/nginx.conf",
        "/etc/nginx/sites-enabled",
        "/usr/local/etc/nginx/nginx.conf"
      ].freeze

      def initialize(config_paths: DEFAULT_CONFIG_PATHS, check_running: true, app_root: Dir.pwd)
        @config_paths = config_paths
        @check_running = check_running
        @app_root = app_root
        @result = Result.new("NginxCheck")
      end

      def run
        check_nginx_installed
        check_config_exists
        check_nginx_running if @check_running
        check_app_nginx_config
        @result
      end

      private

      def check_nginx_installed
        nginx_path = `which nginx 2>/dev/null`.strip
        if nginx_path.empty?
          @result.add_warning("nginx binary not found in PATH; nginx may not be installed")
        else
          @result.add_info("nginx found at #{nginx_path}")
        end
      end

      def check_config_exists
        found = @config_paths.find { |p| File.exist?(p) }
        if found
          @result.add_info("nginx config found at #{found}")
        else
          @result.add_warning("No nginx config found in standard locations: #{@config_paths.join(', ')}")
        end
      end

      def check_nginx_running
        output = `pgrep -x nginx 2>/dev/null`.strip
        if output.empty?
          @result.add_warning("nginx process does not appear to be running")
        else
          @result.add_info("nginx is running (pids: #{output.split.join(', ')})")
        end
      rescue StandardError => e
        @result.add_warning("Could not check nginx process status: #{e.message}")
      end

      def check_app_nginx_config
        app_config = File.join(@app_root, "config", "nginx.conf")
        if File.exist?(app_config)
          @result.add_info("App-level nginx config found at #{app_config}")
        else
          @result.add_info("No app-level nginx config at config/nginx.conf (optional)")
        end
      end
    end
  end
end
