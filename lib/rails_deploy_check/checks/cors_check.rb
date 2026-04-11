# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class CorsCheck
      CHECK_NAME = "CORS"

      KNOWN_CORS_GEMS = %w[rack-cors].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @allowed_origins = options[:allowed_origins]
      end

      def run
        result = Result.new(CHECK_NAME)

        check_cors_gem_in_lockfile(result)
        check_cors_initializer_exists(result)
        check_wildcard_origin(result)

        result
      end

      private

      def check_cors_gem_in_lockfile(result)
        lockfile = File.join(@app_path, "Gemfile.lock")

        unless File.exist?(lockfile)
          result.add_info("Gemfile.lock not found; skipping CORS gem check")
          return
        end

        content = File.read(lockfile)
        if KNOWN_CORS_GEMS.any? { |gem| content.include?(gem) }
          result.add_info("CORS gem detected in Gemfile.lock")
        else
          result.add_warning("No CORS gem (e.g. rack-cors) found in Gemfile.lock")
        end
      end

      def check_cors_initializer_exists(result)
        initializer = File.join(@app_path, "config", "initializers", "cors.rb")

        if File.exist?(initializer)
          result.add_info("CORS initializer found at config/initializers/cors.rb")
        else
          result.add_warning("No CORS initializer found at config/initializers/cors.rb")
        end
      end

      def check_wildcard_origin(result)
        initializer = File.join(@app_path, "config", "initializers", "cors.rb")
        return unless File.exist?(initializer)

        content = File.read(initializer)

        if content.match?(/origins\s+['"]\*['"]/) || content.match?(/origins\s+\/\.\.\*\//)  
          if @allowed_origins.nil?
            result.add_warning("Wildcard origin ('*') detected in CORS config — consider restricting allowed origins")
          else
            result.add_info("Wildcard origin detected but allowed_origins override is configured")
          end
        else
          result.add_info("CORS origins appear to be restricted (no wildcard detected)")
        end
      end
    end
  end
end
