# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class SentryCheck
      CHECK_NAME = "Sentry"

      KNOWN_DSN_HOSTS = [
        "sentry.io",
        "o0.ingest.sentry.io"
      ].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @dsn = options[:sentry_dsn] || ENV["SENTRY_DSN"]
        @environment = options[:environment] || ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "production"
      end

      def run
        result = Result.new(CHECK_NAME)

        check_dsn_present(result)
        check_dsn_format(result) if @dsn
        check_gem_in_lockfile(result)
        check_initializer_exists(result)

        result
      end

      private

      def check_dsn_present(result)
        if @dsn.nil? || @dsn.strip.empty?
          result.add_warning("SENTRY_DSN environment variable is not set; Sentry error tracking will be disabled")
        else
          result.add_info("SENTRY_DSN is configured")
        end
      end

      def check_dsn_format(result)
        uri = URI.parse(@dsn)
        unless uri.scheme&.match?(/\Ahttps?\z/) && uri.host
          result.add_error("SENTRY_DSN does not appear to be a valid URL: #{@dsn}")
          return
        end

        unless KNOWN_DSN_HOSTS.any? { |h| uri.host.end_with?(h) }
          result.add_warning("SENTRY_DSN host '#{uri.host}' is not a recognised Sentry ingest host")
        end
      rescue URI::InvalidURIError
        result.add_error("SENTRY_DSN is not a valid URI: #{@dsn}")
      end

      def check_gem_in_lockfile(result)
        lockfile = File.join(@app_path, "Gemfile.lock")
        return result.add_info("Gemfile.lock not found; skipping Sentry gem check") unless File.exist?(lockfile)

        content = File.read(lockfile)
        if content.match?(/^\s+sentry-ruby\b/) || content.match?(/^\s+sentry-rails\b/)
          result.add_info("Sentry gem detected in Gemfile.lock")
        else
          result.add_warning("sentry-ruby / sentry-rails not found in Gemfile.lock; error tracking may not be active")
        end
      end

      def check_initializer_exists(result)
        initializer = File.join(@app_path, "config", "initializers", "sentry.rb")
        if File.exist?(initializer)
          result.add_info("Sentry initializer found at config/initializers/sentry.rb")
        else
          result.add_warning("No Sentry initializer found at config/initializers/sentry.rb")
        end
      end
    end
  end
end
