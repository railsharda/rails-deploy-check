# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module TimezoneCheckIntegration
      def self.build(options = {})
        app_path = options.fetch(:app_path, Dir.pwd)
        TimezoneCheck.new(
          app_path: app_path,
          tz_env: options[:tz_env] || ENV["TZ"],
          rails_config_path: options[:rails_config_path] ||
            File.join(app_path, "config", "application.rb")
        )
      end

      def self.register(runner)
        return unless applicable?

        runner.register(:timezone, build(app_path: runner.app_path))
      end

      def self.applicable?
        rails_app? || tz_env_present?
      end

      def self.rails_app?
        File.exist?(File.join(Dir.pwd, "config", "application.rb"))
      end

      def self.tz_env_present?
        !ENV["TZ"].nil? && !ENV["TZ"].empty?
      end
    end
  end
end
