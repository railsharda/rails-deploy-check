# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module MaintenanceCheckIntegration
      def self.build(options = {})
        app_path = options.fetch(:app_path, Dir.pwd)

        MaintenanceCheck.new(
          app_path: app_path,
          maintenance_file: options[:maintenance_file],
          check_public_dir: options.fetch(:check_public_dir, true)
        )
      end

      def self.register(config)
        config.checks << build(
          app_path: config.app_path,
          maintenance_file: config.respond_to?(:maintenance_file) ? config.maintenance_file : nil
        )
      end

      def self.applicable?(app_path = Dir.pwd)
        rails_app?(app_path) || tmp_dir_present?(app_path)
      end

      def self.rails_app?(app_path)
        File.exist?(File.join(app_path, "config", "application.rb"))
      end

      def self.tmp_dir_present?(app_path)
        File.directory?(File.join(app_path, "tmp"))
      end
    end
  end
end
