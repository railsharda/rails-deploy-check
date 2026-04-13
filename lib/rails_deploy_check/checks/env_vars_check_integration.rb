# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module EnvVarsCheckIntegration
      class << self
        def build(options = {})
          EnvVarsCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:env_vars, build)
        end

        def applicable?
          rails_app? || dotenv_present? || any_required_vars_set?
        end

        def rails_app?
          File.exist?("config/application.rb") || File.exist?("config/environment.rb")
        end

        def dotenv_present?
          File.exist?(".env") || File.exist?(".env.example")
        end

        def any_required_vars_set?
          EnvVarsCheck::COMMON_REQUIRED_VARS.any? { |var| ENV.key?(var) }
        end
      end
    end
  end
end
