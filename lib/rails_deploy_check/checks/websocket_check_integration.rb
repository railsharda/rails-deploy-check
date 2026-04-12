# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module WebsocketCheckIntegration
      def self.build(options = {})
        WebsocketCheck.new(options)
      end

      def self.register(registry, options = {})
        return unless applicable?(options)

        registry << build(options)
      end

      def self.applicable?(options = {})
        app_path = options.fetch(:app_path, Dir.pwd)
        action_cable_present?(app_path) ||
          websocket_url_present? ||
          action_cable_url_present?
      end

      def self.action_cable_present?(app_path)
        cable_yml = File.join(app_path, "config", "cable.yml")
        return true if File.exist?(cable_yml)

        lockfile = File.join(app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).include?("actioncable")
      end

      def self.websocket_url_present?
        url = ENV["WEBSOCKET_URL"]
        !url.nil? && !url.strip.empty?
      end

      def self.action_cable_url_present?
        url = ENV["ACTION_CABLE_URL"]
        !url.nil? && !url.strip.empty?
      end
    end
  end
end
