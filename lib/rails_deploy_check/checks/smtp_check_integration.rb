# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module SmtpCheckIntegration
      def self.build(config = {})
        SmtpCheck.new(config)
      end

      def self.register(runner)
        return unless applicable?

        runner.register(:smtp, build)
      end

      def self.applicable?
        smtp_host_present? || rails_smtp_configured?
      end

      def self.smtp_host_present?
        host = ENV["SMTP_HOST"]
        !host.nil? && !host.strip.empty?
      end

      def self.rails_smtp_configured?
        return false unless defined?(Rails)

        begin
          delivery = Rails.application.config.action_mailer.delivery_method
          delivery == :smtp
        rescue
          false
        end
      end
    end
  end
end
