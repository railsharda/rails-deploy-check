# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class MemoryCheck
      DEFAULT_MINIMUM_MB = 256
      DEFAULT_WARNING_MB = 512

      def initialize(config = {})
        @minimum_mb = config.fetch(:minimum_mb, DEFAULT_MINIMUM_MB)
        @warning_mb = config.fetch(:warning_mb, DEFAULT_WARNING_MB)
      end

      def run
        result = Result.new(name: "Memory Check")

        available = available_memory_mb

        if available.nil?
          result.add_warning("Could not determine available memory")
          return result
        end

        check_minimum_memory(result, available)
        check_warning_threshold(result, available)

        result.add_info("Available memory: #{available} MB") if result.passed?
        result
      end

      private

      def check_minimum_memory(result, available)
        if available < @minimum_mb
          result.add_error(
            "Available memory (#{available} MB) is below minimum threshold (#{@minimum_mb} MB)"
          )
        end
      end

      def check_warning_threshold(result, available)
        return if available < @minimum_mb

        if available < @warning_mb
          result.add_warning(
            "Available memory (#{available} MB) is below recommended threshold (#{@warning_mb} MB)"
          )
        end
      end

      def available_memory_mb
        if File.exist?("/proc/meminfo")
          read_proc_meminfo
        elsif (output = run_command("vm_stat"))
          parse_vm_stat(output)
        end
      rescue StandardError
        nil
      end

      def read_proc_meminfo
        content = File.read("/proc/meminfo")
        match = content.match(/MemAvailable:\s+(\d+)\s+kB/)
        return nil unless match

        match[1].to_i / 1024
      end

      def parse_vm_stat(output)
        page_size = 4096
        free_pages = output.match(/Pages free:\s+(\d+)/)
        return nil unless free_pages

        (free_pages[1].to_i * page_size) / (1024 * 1024)
      end

      def run_command(cmd)
        output = `#{cmd} 2>/dev/null`
        $?.success? ? output : nil
      rescue StandardError
        nil
      end
    end
  end
end
