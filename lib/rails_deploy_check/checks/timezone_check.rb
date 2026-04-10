module RailsDeployCheck
  module Checks
    class TimezoneCheck
      VALID_RAILS_TIMEZONES = [
        "UTC", "Eastern Time (US & Canada)", "Central Time (US & Canada)",
        "Mountain Time (US & Canada)", "Pacific Time (US & Canada)",
        "London", "Berlin", "Tokyo", "Sydney", "Mumbai"
      ].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @require_utc = options.fetch(:require_utc, false)
      end

      def run
        result = Result.new("TimezoneCheck")

        check_tz_environment_variable(result)
        check_rails_application_config(result)
        check_database_timezone_consistency(result)

        result
      end

      private

      def check_tz_environment_variable(result)
        tz = ENV["TZ"]
        if tz.nil? || tz.empty?
          result.add_warning("TZ environment variable is not set; system default timezone will be used")
        elsif @require_utc && tz != "UTC"
          result.add_error("TZ environment variable is '#{tz}' but UTC is required")
        else
          result.add_info("TZ environment variable is set to '#{tz}'")
        end
      end

      def check_rails_application_config(result)
        config_file = File.join(@app_path, "config", "application.rb")

        unless File.exist?(config_file)
          result.add_warning("config/application.rb not found; cannot verify Rails timezone configuration")
          return
        end

        content = File.read(config_file)
        tz_match = content.match(/config\.time_zone\s*=\s*['"]([^'"]+)['"]/) ||
                   content.match(/config\.time_zone\s*=\s*(\S+)/)

        if tz_match
          configured_tz = tz_match[1]
          if @require_utc && configured_tz != "UTC"
            result.add_error("config.time_zone is '#{configured_tz}' but UTC is required")
          else
            result.add_info("Rails time_zone configured as '#{configured_tz}'")
          end
        else
          result.add_warning("config.time_zone is not explicitly set in config/application.rb")
        end
      end

      def check_database_timezone_consistency(result)
        database_yml = File.join(@app_path, "config", "database.yml")

        unless File.exist?(database_yml)
          result.add_warning("config/database.yml not found; cannot verify database timezone settings")
          return
        end

        content = File.read(database_yml)
        if content.include?("variables:") && content.match(/time_zone:\s*['"](\S+)['"]/)
          db_tz = content.match(/time_zone:\s*['"]([^'"]+)['"]/)&.captures&.first
          result.add_info("Database timezone variable configured as '#{db_tz}'")
        else
          result.add_info("No explicit database timezone variable found in database.yml")
        end
      end
    end
  end
end
