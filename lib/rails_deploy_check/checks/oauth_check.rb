module RailsDeployCheck
  module Checks
    class OauthCheck
      KNOWN_PROVIDERS = %w[google github facebook twitter okta auth0].freeze

      PROVIDER_ENV_KEYS = {
        "google"   => %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET],
        "github"   => %w[GITHUB_CLIENT_ID GITHUB_CLIENT_SECRET],
        "facebook" => %w[FACEBOOK_APP_ID FACEBOOK_APP_SECRET],
        "twitter"  => %w[TWITTER_API_KEY TWITTER_API_SECRET],
        "okta"     => %w[OKTA_CLIENT_ID OKTA_CLIENT_SECRET OKTA_DOMAIN],
        "auth0"    => %w[AUTH0_CLIENT_ID AUTH0_CLIENT_SECRET AUTH0_DOMAIN]
      }.freeze

      def initialize(options = {})
        @app_path  = options.fetch(:app_path, Dir.pwd)
        @providers = Array(options[:providers])
        @env       = options.fetch(:env, ENV)
      end

      def run
        result = Result.new(name: "OAuth")

        check_omniauth_gem_available(result)
        check_providers_configured(result)
        check_callback_url_present(result)

        result
      end

      private

      def check_omniauth_gem_available(result)
        lockfile = File.join(@app_path, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found; cannot verify omniauth gem")
          return
        end

        content = File.read(lockfile)
        if content.match?(/^\s+omniauth\b/)
          result.add_info("omniauth gem found in Gemfile.lock")
        else
          result.add_info("omniauth gem not detected; skipping OAuth credential checks")
        end
      end

      def check_providers_configured(result)
        return if @providers.empty?

        @providers.each do |provider|
          keys = PROVIDER_ENV_KEYS[provider.to_s.downcase]
          if keys.nil?
            result.add_warning("Unknown OAuth provider '#{provider}'; cannot validate credentials")
            next
          end

          missing = keys.reject { |k| @env[k].to_s.strip != "" }
          if missing.empty?
            result.add_info("#{provider} OAuth credentials present")
          else
            result.add_error("Missing #{provider} OAuth environment variables: #{missing.join(', ')}")
          end
        end
      end

      def check_callback_url_present(result)
        url = @env["OAUTH_CALLBACK_URL"] || @env["APP_HOST"] || @env["APPLICATION_HOST"]
        if url.to_s.strip.empty?
          result.add_warning("No callback URL detected (OAUTH_CALLBACK_URL / APP_HOST not set)")
        else
          result.add_info("OAuth callback base URL: #{url}")
        end
      end
    end
  end
end
