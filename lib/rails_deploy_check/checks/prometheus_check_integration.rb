# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module PrometheusCheckIntegration
      class << self
        def build(options = {})
          PrometheusCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:prometheus, method(:build))
        end

        def applicable?
          prometheus_url_present? || prometheus_gem_in_lockfile?
        end

        def prometheus_url_present?
          url = ENV["PROMETHEUS_METRICS_URL"] || ENV["PROMETHEUS_PUSHGATEWAY_URL"]
          !url.nil? && !url.strip.empty?
        end

        def prometheus_gem_in_lockfile?(app_root: Dir.pwd)
          lockfile = File.join(app_root, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          content = File.read(lockfile)
          content.include?("prometheus-client") || content.include?("yabeda")
        end
      end
    end
  end
end
