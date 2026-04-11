# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module YarnCheckIntegration
      def self.build(app_path: Dir.pwd)
        YarnCheck.new(app_path: app_path)
      end

      def self.register(config)
        return unless applicable?(config.app_path)

        config.checks << build(app_path: config.app_path)
      end

      def self.applicable?(app_path = Dir.pwd)
        yarn_lock_present?(app_path) || package_json_present?(app_path)
      end

      def self.yarn_lock_present?(app_path = Dir.pwd)
        File.exist?(File.join(app_path, "yarn.lock"))
      end

      def self.package_json_present?(app_path = Dir.pwd)
        File.exist?(File.join(app_path, "package.json"))
      end
    end
  end
end
