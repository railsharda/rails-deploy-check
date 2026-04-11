# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class NewrelicCheck
      attr_reader :result

      def initialize(app_root: Dir.pwd, license_key: nil, app_name: nil)
        @app_root = app_root
        @license_key = license_key || ENV["NEW_RELIC_LICENSE_KEY"]
        @app_name = app_name || ENV["NEW_RELIC_APP_NAME"]
        @result = Result.new("NewRelic")
      end

      def run
        check_gem_in_lockfile
        check_license_key_present
        check_app_name_present
        check_config_file_exists
        result
      end

      private

      def check_gem_in_lockfile
        unless newrelic_in_lockfile?
          result.add_info("newrelic_rpm gem not found in Gemfile.lock — skipping New Relic checks")
        end
      end

      def check_license_key_present
        return unless newrelic_in_lockfile?

        if @license_key.nil? || @license_key.strip.empty?
          result.add_error("NEW_RELIC_LICENSE_KEY is not set")
        elsif @license_key.length < 32
          result.add_warning("NEW_RELIC_LICENSE_KEY appears too short (expected 40 chars)")
        else
          result.add_info("NEW_RELIC_LICENSE_KEY is present")
        end
      end

      def check_app_name_present
        return unless newrelic_in_lockfile?

        if @app_name.nil? || @app_name.strip.empty?
          result.add_warning("NEW_RELIC_APP_NAME is not set — New Relic will use a default name")
        else
          result.add_info("NEW_RELIC_APP_NAME is set to '#{@app_name}'")
        end
      end

      def check_config_file_exists
        return unless newrelic_in_lockfile?

        config_path = File.join(@app_root, "config", "newrelic.yml")
        if File.exist?(config_path)
          result.add_info("New Relic config file found at config/newrelic.yml")
        else
          result.add_warning("config/newrelic.yml not found — New Relic will rely on environment variables only")
        end
      end

      def newrelic_in_lockfile?
        lockfile = File.join(@app_root, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).include?("newrelic_rpm")
      end
    end
  end
end
