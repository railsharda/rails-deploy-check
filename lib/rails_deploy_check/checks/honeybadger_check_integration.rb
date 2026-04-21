# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module HoneybadgerCheckIntegration
      class << self
        def build(options = {})
          HoneybadgerCheck.new(options)
        end

        def register(registry)
          return unless applicable?

          registry.register(:honeybadger, method(:build))
        end

        def applicable?
          honeybadger_api_key_present? || honeybadger_in_lockfile?
        end

        def honeybadger_api_key_present?
          key = ENV["HONEYBADGER_API_KEY"]
          key && !key.strip.empty?
        end

        def honeybadger_in_lockfile?
          lockfile = File.join(Dir.pwd, "Gemfile.lock")
          return false unless File.exist?(lockfile)

          File.read(lockfile).match?(/^\s+honeybadger\b/)
        end
      end
    end
  end
end
