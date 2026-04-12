# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class ExternalServicesCheck
      KNOWN_SERVICES = {
        "STRIPE_SECRET_KEY" => "Stripe",
        "STRIPE_PUBLISHABLE_KEY" => "Stripe",
        "TWILIO_ACCOUNT_SID" => "Twilio",
        "TWILIO_AUTH_TOKEN" => "Twilio",
        "SENDGRID_API_KEY" => "SendGrid",
        "MAILGUN_API_KEY" => "Mailgun",
        "AWS_ACCESS_KEY_ID" => "AWS",
        "GOOGLE_OAUTH_CLIENT_ID" => "Google OAuth",
        "GITHUB_CLIENT_ID" => "GitHub OAuth",
        "PUSHER_APP_ID" => "Pusher",
        "ALGOLIA_APPLICATION_ID" => "Algolia"
      }.freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @required_services = options.fetch(:required_services, [])
        @check_reachability = options.fetch(:check_reachability, false)
      end

      def run
        result = Result.new("External Services")

        check_required_services(result)
        check_known_service_keys(result)

        result
      end

      private

      def check_required_services(result)
        return if @required_services.empty?

        @required_services.each do |service_env_key|
          value = ENV[service_env_key.to_s]
          if value.nil? || value.strip.empty?
            result.add_error("Required external service key missing: #{service_env_key}")
          else
            result.add_info("External service key present: #{service_env_key}")
          end
        end
      end

      def check_known_service_keys(result)
        detected = KNOWN_SERVICES.each_with_object({}) do |(env_key, service_name), acc|
          value = ENV[env_key]
          next if value.nil? || value.strip.empty?

          acc[service_name] ||= []
          acc[service_name] << env_key
        end

        if detected.empty?
          result.add_info("No well-known external service credentials detected")
          return
        end

        detected.each do |service_name, keys|
          result.add_info("#{service_name} credentials detected (#{keys.join(', ')}). Ensure these are valid for the target environment.")
        end

        check_partial_credentials(result)
      end

      def check_partial_credentials(result)
        stripe_id = ENV["STRIPE_SECRET_KEY"]
        stripe_pub = ENV["STRIPE_PUBLISHABLE_KEY"]
        if stripe_id && !stripe_pub
          result.add_warning("STRIPE_SECRET_KEY is set but STRIPE_PUBLISHABLE_KEY is missing")
        elsif stripe_pub && !stripe_id
          result.add_warning("STRIPE_PUBLISHABLE_KEY is set but STRIPE_SECRET_KEY is missing")
        end

        twilio_sid = ENV["TWILIO_ACCOUNT_SID"]
        twilio_token = ENV["TWILIO_AUTH_TOKEN"]
        if twilio_sid && !twilio_token
          result.add_warning("TWILIO_ACCOUNT_SID is set but TWILIO_AUTH_TOKEN is missing")
        elsif twilio_token && !twilio_sid
          result.add_warning("TWILIO_AUTH_TOKEN is set but TWILIO_ACCOUNT_SID is missing")
        end
      end
    end
  end
end
