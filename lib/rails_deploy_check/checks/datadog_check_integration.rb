# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module DatadogCheckIntegration
      class << self
        def build(options = {})
          DatadogCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:datadog, method(:build))
        end

        def applicable?
          datadog_api_key_present? || datadog_gem_in_lockfile?
        end

        def datadog_api_key_present?
          key = ENV["DD_API_KEY"]
          !key.nil? && !key.strip.empty?
        end

        def datadog_gem_in_lockfile?
          lockfile = File.join(Dir.pwd, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          content = File.read(lockfile)
          content.match?(/^\s+(?:ddtrace|datadog)\s+\(/) 
        end
      end
    end
  end
end
