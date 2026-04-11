# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module NginxCheckIntegration
      def self.build(options = {})
        NginxCheck.new(
          config_paths: options.fetch(:config_paths, NginxCheck::DEFAULT_CONFIG_PATHS),
          check_running: options.fetch(:check_running, true),
          app_root: options.fetch(:app_root, Dir.pwd)
        )
      end

      def self.register(registry)
        registry.register(:nginx, method(:build))
      end

      def self.applicable?
        return true if nginx_installed?
        return true if nginx_config_present?

        false
      end

      def self.nginx_installed?
        !`which nginx 2>/dev/null`.strip.empty?
      rescue StandardError
        false
      end

      def self.nginx_config_present?
        NginxCheck::DEFAULT_CONFIG_PATHS.any? { |p| File.exist?(p) } ||
          File.exist?(File.join(Dir.pwd, "config", "nginx.conf"))
      end
    end
  end
end
