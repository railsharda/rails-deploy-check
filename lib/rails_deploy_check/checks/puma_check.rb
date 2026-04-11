# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class PumaCheck
      DEFAULT_CONFIG_PATHS = [
        "config/puma.rb",
        "config/puma/production.rb"
      ].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @min_threads = options.fetch(:min_threads, 1)
        @min_workers = options.fetch(:min_workers, 1)
      end

      def run
        result = Result.new(name: "Puma")

        check_config_file_exists(result)
        check_workers_configured(result)
        check_threads_configured(result)
        check_bind_configured(result)

        result
      end

      private

      def check_config_file_exists(result)
        if config_path
          result.add_info("Puma config found: #{config_path}")
        else
          result.add_warning("No Puma config file found (checked: #{DEFAULT_CONFIG_PATHS.join(', ')})")
        end
      end

      def check_workers_configured(result)
        return unless config_path

        content = File.read(full_config_path)
        if content.match?(/^\s*workers\s+/)
          workers_line = content.lines.grep(/^\s*workers\s+/).first&.strip
          result.add_info("Puma workers configured: #{workers_line}")
        else
          result.add_warning("Puma 'workers' not configured in #{config_path} — single-process mode")
        end
      end

      def check_threads_configured(result)
        return unless config_path

        content = File.read(full_config_path)
        if content.match?(/^\s*threads\s+/)
          threads_line = content.lines.grep(/^\s*threads\s+/).first&.strip
          result.add_info("Puma threads configured: #{threads_line}")
        else
          result.add_warning("Puma 'threads' not explicitly configured in #{config_path}")
        end
      end

      def check_bind_configured(result)
        return unless config_path

        content = File.read(full_config_path)
        if content.match?(/^\s*bind\s+/) || content.match?(/^\s*port\s+/)
          result.add_info("Puma bind/port configured in #{config_path}")
        else
          result.add_warning("Puma bind or port not explicitly set in #{config_path}")
        end
      end

      def config_path
        @config_path ||= DEFAULT_CONFIG_PATHS.find do |path|
          File.exist?(File.join(@app_path, path))
        end
      end

      def full_config_path
        File.join(@app_path, config_path)
      end
    end
  end
end
