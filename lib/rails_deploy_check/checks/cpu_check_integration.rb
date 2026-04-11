module RailsDeployCheck
  module Checks
    module CpuCheckIntegration
      def self.build(options = {})
        CpuCheck.new(options)
      end

      def self.register(runner)
        return unless applicable?

        runner.register(:cpu, build)
      end

      def self.applicable?
        linux? || macos?
      end

      def self.linux?
        RUBY_PLATFORM.include?("linux")
      end

      def self.macos?
        RUBY_PLATFORM.include?("darwin")
      end

      def self.detected_platform
        if linux?
          :linux
        elsif macos?
          :macos
        else
          :unknown
        end
      end
    end
  end
end
