# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module GzipCheckIntegration
      class << self
        def build(options = {})
          GzipCheck.new(
            app_path: options.fetch(:app_path, Dir.pwd),
            check_nginx: options.fetch(:check_nginx, nginx_config_present?),
            check_assets: options.fetch(:check_assets, assets_dir_present?)
          )
        end

        def register(registry)
          return unless applicable?

          registry.register(:gzip, -> (opts) { build(opts) })
        end

        def applicable?
          rails_app? || nginx_config_present?
        end

        def rails_app?
          File.exist?("config/application.rb") || File.exist?("config/environment.rb")
        end

        def nginx_config_present?
          [
            "config/nginx.conf",
            "config/deploy/nginx.conf"
          ].any? { |p| File.exist?(p) }
        end

        def assets_dir_present?
          File.directory?("public/assets")
        end
      end
    end
  end
end
