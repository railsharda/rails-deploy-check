module RailsDeployCheck
  module Checks
    class CpuCheck
      DEFAULT_WARNING_THRESHOLD = 80.0
      DEFAULT_CRITICAL_THRESHOLD = 95.0

      def initialize(options = {})
        @warning_threshold = options.fetch(:warning_threshold, DEFAULT_WARNING_THRESHOLD)
        @critical_threshold = options.fetch(:critical_threshold, DEFAULT_CRITICAL_THRESHOLD)
        @app_path = options.fetch(:app_path, Dir.pwd)
      end

      def run
        result = Result.new("CPU Check")

        check_cpu_load(result)
        check_cpu_count(result)

        result
      end

      private

      def check_cpu_load(result)
        usage = current_cpu_usage

        if usage.nil?
          result.add_warning("Could not determine CPU usage (unsupported platform)")
          return
        end

        if usage >= @critical_threshold
          result.add_error("CPU usage is critically high: #{usage.round(1)}% (threshold: #{@critical_threshold}%)")
        elsif usage >= @warning_threshold
          result.add_warning("CPU usage is elevated: #{usage.round(1)}% (threshold: #{@warning_threshold}%)")
        else
          result.add_info("CPU usage is normal: #{usage.round(1)}%")
        end
      end

      def check_cpu_count(result)
        count = cpu_count
        if count.nil?
          result.add_warning("Could not determine CPU count")
        elsif count < 2
          result.add_warning("Only #{count} CPU core(s) detected; consider upgrading for production workloads")
        else
          result.add_info("#{count} CPU core(s) available")
        end
      end

      def current_cpu_usage
        if linux?
          parse_linux_cpu_usage
        elsif macos?
          parse_macos_cpu_usage
        end
      end

      def parse_linux_cpu_usage
        output = `top -bn1 | grep 'Cpu(s)' 2>/dev/null`.strip
        return nil if output.empty?

        idle_match = output.match(/(\d+\.\d+)\s*id/)
        return nil unless idle_match

        100.0 - idle_match[1].to_f
      rescue
        nil
      end

      def parse_macos_cpu_usage
        output = `top -l1 -n0 | grep 'CPU usage' 2>/dev/null`.strip
        return nil if output.empty?

        idle_match = output.match(/(\d+\.\d+)%\s*idle/)
        return nil unless idle_match

        100.0 - idle_match[1].to_f
      rescue
        nil
      end

      def cpu_count
        if linux?
          `nproc 2>/dev/null`.strip.to_i.nonzero?
        elsif macos?
          `sysctl -n hw.ncpu 2>/dev/null`.strip.to_i.nonzero?
        end
      rescue
        nil
      end

      def linux?
        RUBY_PLATFORM.include?("linux")
      end

      def macos?
        RUBY_PLATFORM.include?("darwin")
      end
    end
  end
end
