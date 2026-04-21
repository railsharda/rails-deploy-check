# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module SslCertificateCheckIntegration
      class << self
        def build(options = {})
          SslCertificateCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:ssl_certificate, build)
        end

        def applicable?
          ssl_host_present? && production_like_environment?
        end

        def ssl_host_present?
          ENV["SSL_HOST"].to_s.strip != "" || ENV["APP_HOST"].to_s.strip != ""
        end

        def production_like_environment?
          env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
          %w[production staging].include?(env)
        end
      end
    end
  end
end
