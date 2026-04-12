# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module RateLimitCheckIntegration
      def self.build(options = {})
        RateLimitCheck.new(options)
      end

      def self.register(runner)
        return unless applicable?

        runner.register_check(build(app_path: runner.app_path))
      end

      def self.applicable?
        rack_attack_present? || production_like_environment?
      end

      def self.rack_attack_present?
        lockfile = File.join(Dir.pwd, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        content = File.read(lockfile)
        content.match?(/^\s+rack-attack\s/) ||
          content.match?(/^\s+rack-throttle\s/) ||
          content.match?(/^\s+rack-shield\s/)
      end

      def self.production_like_environment?
        env = ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
        %w[production staging].include?(env)
      end
    end
  end
end
