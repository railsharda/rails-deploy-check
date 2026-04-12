module RailsDeployCheck
  module Checks
    module CspCheckIntegration
      class << self
        def build(options = {})
          CspCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:csp, build)
        end

        def applicable?
          rails_app? && production_like_environment?
        end

        def rails_app?
          File.exist?("config/application.rb") || File.exist?("Gemfile")
        end

        def production_like_environment?
          env = ENV["RAILS_ENV"] || "development"
          %w[production staging].include?(env)
        end

        def secure_headers_present?
          lockfile = "Gemfile.lock"
          return false unless File.exist?(lockfile)
          File.read(lockfile).match?(/^\s+secure_headers\s/)
        end
      end
    end
  end
end
