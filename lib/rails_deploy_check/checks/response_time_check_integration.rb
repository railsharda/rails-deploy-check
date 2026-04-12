# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module ResponseTimeCheckIntegration
      class << self
        def build(options = {})
          ResponseTimeCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:response_time, build)
        end

        def applicable?
          url_present? || production_like_environment?
        end

        def detect_url
          ENV["HEALTH_CHECK_URL"] ||
            ENV["APP_URL"]         ||
            ENV["HEROKU_APP_NAME"] && "https://#{ENV['HEROKU_APP_NAME']}.herokuapp.com/"
        end

        private

        def url_present?
          url = detect_url
          url && !url.strip.empty?
        end

        def production_like_environment?
          %w[production staging].include?(ENV["RAILS_ENV"])
        end
      end
    end
  end
end
