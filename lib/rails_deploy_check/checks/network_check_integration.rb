# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module NetworkCheckIntegration
      class << self
        def build(options = {})
          hosts = detect_custom_hosts
          NetworkCheck.new(options.merge(hosts: hosts))
        end

        def register(registry)
          return unless applicable?

          registry.register(:network, -> (opts) { build(opts) })
        end

        def applicable?
          true
        end

        private

        def detect_custom_hosts
          hosts = []

          if (db_url = ENV["DATABASE_URL"])
            uri = URI.parse(db_url)
            hosts << { host: uri.host, port: uri.port || 5432, label: "DATABASE_URL host" } if uri.host
          rescue URI::InvalidURIError
            nil
          end

          if (redis_url = ENV["REDIS_URL"])
            uri = URI.parse(redis_url)
            hosts << { host: uri.host, port: uri.port || 6379, label: "REDIS_URL host" } if uri.host
          rescue URI::InvalidURIError
            nil
          end

          hosts
        end
      end
    end
  end
end
