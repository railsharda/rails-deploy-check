# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class MailCheck
      KNOWN_DELIVERY_METHODS = %w[
        smtp sendmail file test
        mailgun postmark ses sparkpost
      ].freeze

      def initialize(config = {})
        @app_path = config.fetch(:app_path, Dir.pwd)
        @env = config.fetch(:env, ENV)
      end

      def run
        result = Result.new(name: "Mail")

        check_delivery_method(result)
        check_smtp_settings(result)
        check_from_address(result)

        result
      end

      private

      def check_delivery_method(result)
        method = @env["ACTION_MAILER_DELIVERY_METHOD"] ||
                 @env["MAIL_DELIVERY_METHOD"]

        if method.nil?
          result.add_warning(
            "ACTION_MAILER_DELIVERY_METHOD is not set; " \
            "Rails will default to :smtp in production"
          )
        elsif !KNOWN_DELIVERY_METHODS.include?(method.downcase)
          result.add_warning(
            "Unrecognised delivery method '#{method}'; " \
            "expected one of: #{KNOWN_DELIVERY_METHODS.join(', ')}"
          )
        else
          result.add_info("Mail delivery method: #{method}")
        end
      end

      def check_smtp_settings(result)
        method = (@env["ACTION_MAILER_DELIVERY_METHOD"] ||
                  @env["MAIL_DELIVERY_METHOD"] || "smtp").downcase

        return unless method == "smtp"

        host = @env["SMTP_HOST"] || @env["SMTP_ADDRESS"]
        port = @env["SMTP_PORT"]

        if host.nil? || host.strip.empty?
          result.add_error(
            "SMTP delivery method selected but SMTP_HOST / SMTP_ADDRESS is not set"
          )
        else
          result.add_info("SMTP host: #{host}#{port ? ":#{port}" : ""} ")
        end
      end

      def check_from_address(result)
        from = @env["MAILER_FROM"] || @env["DEFAULT_FROM_EMAIL"]

        if from.nil? || from.strip.empty?
          result.add_warning(
            "No default From address configured " \
            "(MAILER_FROM or DEFAULT_FROM_EMAIL); " \
            "outgoing mail may be rejected"
          )
        elsif !from.include?("@")
          result.add_error("MAILER_FROM / DEFAULT_FROM_EMAIL '#{from}' does not look like a valid email address")
        else
          result.add_info("Default mailer From address: #{from}")
        end
      end
    end
  end
end
