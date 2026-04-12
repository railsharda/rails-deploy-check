require_relative "oauth_check"

module RailsDeployCheck
  module Checks
    module OauthCheckIntegration
      class << self
        def build(options = {})
          providers = detect_providers(options)
          OauthCheck.new(options.merge(providers: providers))
        end

        def register(registry)
          return unless applicable?

          registry.register(:oauth) { |opts| build(opts) }
        end

        def applicable?
          omniauth_in_lockfile? || any_provider_env_present?
        end

        def omniauth_in_lockfile?(app_path: Dir.pwd)
          lockfile = File.join(app_path, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          File.read(lockfile).match?(/^\s+omniauth\b/)
        end

        def any_provider_env_present?
          OauthCheck::PROVIDER_ENV_KEYS.values.flatten.any? { |k| ENV[k].to_s.strip != "" }
        end

        private

        def detect_providers(options)
          return options[:providers] if options[:providers]&.any?

          OauthCheck::PROVIDER_ENV_KEYS.filter_map do |provider, keys|
            provider if keys.any? { |k| ENV[k].to_s.strip != "" }
          end
        end
      end
    end
  end
end
