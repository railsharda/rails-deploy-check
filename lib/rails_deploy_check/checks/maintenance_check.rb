# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class MaintenanceCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @maintenance_file = options.fetch(:maintenance_file, nil)
        @check_public_dir = options.fetch(:check_public_dir, true)
      end

      def run
        result = Result.new(name: "Maintenance Mode")

        check_maintenance_file_not_active(result)
        check_public_maintenance_page(result)
        check_maintenance_env_variable(result)

        result
      end

      private

      def check_maintenance_file_not_active(result)
        path = maintenance_file_path
        if File.exist?(path)
          result.add_error("Maintenance mode is active: #{path} exists. Remove it before deploying.")
        else
          result.add_info("No maintenance lock file found (#{path})")
        end
      end

      def check_public_maintenance_page(result)
        return unless @check_public_dir

        maintenance_html = File.join(@app_path, "public", "maintenance.html")
        if File.exist?(maintenance_html)
          result.add_info("Maintenance page found at public/maintenance.html")
        else
          result.add_warning("No maintenance page found at public/maintenance.html — consider adding one for graceful downtime")
        end
      end

      def check_maintenance_env_variable(result)
        if ENV["MAINTENANCE_MODE"].to_s.downcase == "true"
          result.add_error("MAINTENANCE_MODE environment variable is set to 'true'. Deployment should not proceed.")
        else
          result.add_info("MAINTENANCE_MODE environment variable is not set or false")
        end
      end

      def maintenance_file_path
        @maintenance_file || File.join(@app_path, "tmp", "maintenance.txt")
      end
    end
  end
end
