# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class GzipCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @check_nginx = options.fetch(:check_nginx, true)
        @check_assets = options.fetch(:check_assets, true)
      end

      def run
        result = Result.new(name: "Gzip Compression")

        check_nginx_gzip_config(result) if @check_nginx
        check_gzipped_assets_exist(result) if @check_assets
        check_rack_deflater_configured(result)

        result
      end

      private

      def check_nginx_gzip_config(result)
        nginx_conf_paths = [
          File.join(@app_path, "config", "nginx.conf"),
          File.join(@app_path, "config", "deploy", "nginx.conf"),
          "/etc/nginx/nginx.conf"
        ]

        found = nginx_conf_paths.find { |p| File.exist?(p) }

        if found
          content = File.read(found)
          if content.match?(/gzip\s+on/)
            result.add_info("Nginx gzip compression is enabled in #{found}")
          else
            result.add_warning("Nginx config found at #{found} but gzip is not enabled")
          end
        else
          result.add_info("No local nginx config found; skipping nginx gzip check")
        end
      end

      def check_gzipped_assets_exist(result)
        manifest_path = Dir.glob(
          File.join(@app_path, "public", "assets", ".sprockets-manifest-*.json")
        ).first || File.join(@app_path, "public", "assets", "manifest.json")

        assets_dir = File.join(@app_path, "public", "assets")

        unless File.directory?(assets_dir)
          result.add_warning("Assets directory not found; run assets:precompile before deploying")
          return
        end

        gz_files = Dir.glob(File.join(assets_dir, "**", "*.gz"))
        if gz_files.any?
          result.add_info("Found #{gz_files.size} pre-compressed (.gz) asset files")
        else
          result.add_warning("No pre-compressed (.gz) assets found; consider enabling asset compression")
        end
      end

      def check_rack_deflater_configured(result)
        config_path = File.join(@app_path, "config", "application.rb")
        production_path = File.join(@app_path, "config", "environments", "production.rb")

        [config_path, production_path].each do |path|
          next unless File.exist?(path)

          content = File.read(path)
          if content.match?(/Rack::Deflater/)
            result.add_info("Rack::Deflater middleware configured in #{File.basename(path)}")
            return
          end
        end

        result.add_warning("Rack::Deflater not configured; consider adding it for gzip compression at the app level")
      end
    end
  end
end
