# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module HttpsRedirectCheckIntegration
      def self.build(options = {})
        HttpsRedirectCheck.new(options)
      end

      def self.register
        return unless applicable?

        RailsDeployCheck.register_check(:https_redirect) do |options|
          build(options)
        end
      end

      def self.applicable?
        rails_app? && production_like_environment?
      end

      def self.rails_app?
        File.exist?("config/application.rb") || File.exist?("config/environment.rb")
      end

      def self.production_like_environment?
        env = ENV["RAILS_ENV"] || "production"
        %w[production staging].include?(env)
      end
    end
  end
end
