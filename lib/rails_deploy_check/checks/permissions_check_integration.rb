module RailsDeployCheck
  module Checks
    module PermissionsCheckIntegration
      def self.build(config = {})
        options = {
          app_path: config.fetch(:app_path, Dir.pwd)
        }

        if config[:writable_dirs]
          options[:writable_dirs] = config[:writable_dirs]
        end

        if config[:readable_files]
          options[:readable_files] = config[:readable_files]
        end

        PermissionsCheck.new(options)
      end

      def self.register(runner)
        runner.register(:permissions, method(:build))
      end

      def self.applicable?(app_path = Dir.pwd)
        rails_app?(app_path)
      end

      def self.rails_app?(app_path)
        File.exist?(File.join(app_path, "config", "application.rb"))
      end
    end
  end
end
