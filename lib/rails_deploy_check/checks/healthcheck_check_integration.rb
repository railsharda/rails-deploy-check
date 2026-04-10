require_relative "healthcheck_check"

module RailsDeployCheck
  module Checks
    module HealthcheckCheckIntegration
      def self.build(config = {})
        HealthcheckCheck.new(config)
      end

      def self.register(runner)
        runner.register(:healthcheck, method(:build))
      end

      # Returns true when the app looks like a Rails app with routes
      def self.applicable?(app_root = Dir.pwd)
        File.exist?(File.join(app_root, "config", "routes.rb"))
      end

      # Attempt to detect a healthcheck path already in routes.rb
      def self.detected_paths(app_root = Dir.pwd)
        routes_file = File.join(app_root, "config", "routes.rb")
        return [] unless File.exist?(routes_file)

        content = File.read(routes_file)
        HealthcheckCheck::DEFAULT_PATHS.select do |p|
          content.include?(p.delete_prefix("/"))
        end
      end
    end
  end
end
