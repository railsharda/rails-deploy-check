require_relative "headers_check"

module RailsDeployCheck
  module Checks
    module HeadersCheckIntegration
      class << self
        def build(options = {})
          app_path = options.fetch(:app_path, Dir.pwd)
          url      = options[:url] || detect_url

          HeadersCheck.new(
            app_path:  app_path,
            url:       url,
            warn_only: options.fetch(:warn_only, false)
          )
        end

        def register(registry)
          return unless applicable?

          registry.register(:headers, build)
        end

        def applicable?
          rails_app? || secure_headers_in_lockfile?
        end

        def rails_app?
          File.exist?(File.join(Dir.pwd, "config", "application.rb"))
        end

        def secure_headers_in_lockfile?
          lockfile = File.join(Dir.pwd, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          File.read(lockfile).match?(/secure_headers/i)
        end

        def detect_url
          ENV["APP_URL"] ||
            ENV["RAILS_RELATIVE_URL_ROOT"] ||
            ENV["HEROKU_APP_NAME"]&.then { |n| "https://#{n}.herokuapp.com" }
        end
      end
    end
  end
end
