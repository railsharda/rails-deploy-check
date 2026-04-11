# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module MemoryCheckIntegration
      def self.build(config = {})
        MemoryCheck.new(config)
      end

      def self.register(checker)
        return unless applicable?

        checker.add_check(build)
      end

      def self.applicable?
        linux? || macos?
      end

      def self.linux?
        File.exist?("/proc/meminfo")
      end

      def self.macos?
        RbConfig::CONFIG["host_os"] =~ /darwin/i
      end
    end
  end
end
