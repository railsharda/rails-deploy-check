# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class FileDescriptorCheck
      DEFAULT_MINIMUM = 1024
      DEFAULT_WARNING_THRESHOLD = 0.85

      def initialize(options = {})
        @minimum = options.fetch(:minimum, DEFAULT_MINIMUM)
        @warning_threshold = options.fetch(:warning_threshold, DEFAULT_WARNING_THRESHOLD)
        @app_path = options.fetch(:app_path, Dir.pwd)
      end

      def run
        result = Result.new(name: "File Descriptors")

        check_ulimit_available(result)
        check_soft_limit(result)
        check_hard_limit(result)

        result
      end

      private

      def check_ulimit_available(result)
        output = `ulimit -n 2>/dev/null`.strip
        if output.empty? || $?.exitstatus != 0
          result.add_warning("Could not determine file descriptor limit via ulimit")
        end
      rescue => e
        result.add_warning("Error checking ulimit: #{e.message}")
      end

      def check_soft_ = read_soft_limit
        return unless soft

        if soft < @minimum
          result.add_error(
            "File descriptor soft limit (#{soft}) is below minimum (#{@minimum}). " \
            "Consider increasing with: ulimit -n #{@minimum}"
          )
        elsif soft < (@minimum / @warning_threshold).to_i
          result.add_warning(
            "File descriptor soft limit (#{soft}) is low. " \
            "Recommended minimum: #{@minimum}"
          )
        else
          result.add_info("File descriptor soft limit: #{soft}")
        end
      rescue => e
        result.add_warning("Error reading soft file descriptor limit: #{e.message}")
      end

      def check_hard_limit(result)
        hard = read_hard_limit
        return unless hard

        if hard != "unlimited" && hard.to_i < @minimum
          result.add_warning(
            "File descriptor hard limit (#{hard}) is below recommended minimum (#{@minimum})"
          )
        else
          result.add_info("File descriptor hard limit: #{hard}")
        end
      rescue => e
        result.add_warning("Error reading hard file descriptor limit: #{e.message}")
      end

      def read_soft_limit
        value = `ulimit -Sn 2>/dev/null`.strip
        return nil if value.empty?
        value == "unlimited" ? Float::INFINITY : value.to_i
      end

      def read_hard_limit
        value = `ulimit -Hn 2>/dev/null`.strip
        return nil if value.empty?
        value == "unlimited" ? "unlimited" : value.to_i
      end
    end
  end
end
