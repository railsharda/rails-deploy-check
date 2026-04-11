# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module CapistranoCheckIntegration
      def self.build(config = {})
        CapistranoCheck.new(config)
      end

      def self.register(runner)
        return unless applicable?

        runner.register(:capistrano, build)
      end

      def self.applicable?
        capfile_present? || capistrano_in_lockfile?
      end

      def self.capfile_present?
        File.exist?(File.join(Dir.pwd, "Capfile"))
      end

      def self.capistrano_in_lockfile?
        lockfile = File.join(Dir.pwd, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        File.read(lockfile).match?(/^\s+capistrano\s+\(/)
      end
    end
  end
end
