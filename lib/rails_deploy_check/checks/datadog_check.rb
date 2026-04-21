# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class DatadogCheck
      KNOWN_DATADOG_GEMS = %w[ddtrace datadog].freeze
      DD_API_KEY_ENV = "DD_API_KEY"
      DD_SITE_PATTERN = /\.datadoghq\.(?:com|eu)$/.freeze

      def initialize(options = {})
        @app_path = options[:app_path] || Dir.pwd
        @api_key = options[:api_key] || ENV[DD_API_KEY_ENV]
        @site = options[:site] || ENV["DD_SITE"]
        @lockfile_path = options[:lockfile_path] || File.join(@app_path, "Gemfile.lock")
      end

      def run
        result = Result.new("Datadog")

        check_api_key_present(result)
        check_gem_in_lockfile(result)
        check_initializer_exists(result)
        check_site_configured(result)

        result
      end

      private

      def check_api_key_present(result)
        if @api_key.nil? || @api_key.strip.empty?
          result.add_error("DD_API_KEY environment variable is not set")
        elsif @api_key.length < 32
          result.add_warning("DD_API_KEY appears too short; verify it is correct")
        else
          result.add_info("DD_API_KEY is present")
        end
      end

      def check_gem_in_lockfile(result)
        unless File.exist?(@lockfile_path)
          result.add_warning("Gemfile.lock not found; cannot verify Datadog gem")
          return
        end

        content = File.read(@lockfile_path)
        found = KNOWN_DATADOG_GEMS.any? { |gem| content.match?(/^\s+#{Regexp.escape(gem)}\s+\(/) }

        if found
          result.add_info("Datadog gem found in Gemfile.lock")
        else
          result.add_warning("No Datadog gem (ddtrace/datadog) found in Gemfile.lock")
        end
      end

      def check_initializer_exists(result)
        initializer = File.join(@app_path, "config", "initializers", "datadog.rb")
        if File.exist?(initializer)
          result.add_info("Datadog initializer found at config/initializers/datadog.rb")
        else
          result.add_warning("No Datadog initializer found at config/initializers/datadog.rb")
        end
      end

      def check_site_configured(result)
        if @site.nil? || @site.strip.empty?
          result.add_info("DD_SITE not set; defaulting to datadoghq.com")
        elsif @site.match?(DD_SITE_PATTERN)
          result.add_info("DD_SITE is set to #{@site}")
        else
          result.add_warning("DD_SITE '#{@site}' does not match a known Datadog site pattern")
        end
      end
    end
  end
end
