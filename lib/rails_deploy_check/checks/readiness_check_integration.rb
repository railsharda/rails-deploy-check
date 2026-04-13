# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module ReadinessCheckIntegration
      class << self
        def build(options = {})
          resolved = options.dup
          resolved[:app_url] ||= detect_url
          ReadinessCheck.new(resolved)
        end

        def register(registry)
          return unless applicable?

          registry.register(:readiness) { |opts| build(opts) }
        end

        def applicable?
          app_url_present? || rails_app?
        end

        def detect_url
          ENV["APP_URL"] ||
            ENV["RAILS_APP_URL"] ||
            ENV["APPLICATION_URL"] ||
            ENV["HEROKU_APP_NAME"]&.then { |name| "https://#{name}.herokuapp.com" }
        end

        private

        def app_url_present?
          !detect_url.nil?
        end

        def rails_app?
          File.exist?("config/application.rb") || File.exist?("config/environment.rb")
        end
      end
    end
  end
end
