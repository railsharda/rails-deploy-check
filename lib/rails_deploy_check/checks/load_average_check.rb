# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class LoadAverageCheck
      attr_reader :result

      DEFAULT_WARNING_THRESHOLD = 2.0
      DEFAULT_CRITICAL_THRESHOLD = 4.0

      def initialize(options = {})
        @warning_threshold = options.fetch(:warning_threshold, DEFAULT_WARNING_THRESHOLD)
        @critical_threshold = options.fetch(:critical_threshold, DEFAULT_CRITICAL_THRESHOLD)
        @result = Result.new("Load Average")
      end

      def run
        load_averages = read_load_averages

        if load_averages.nil?
          result.add_warning("Could not determine system load average")
          return result
        end

        check_load_average(load_averages)
        check_cpu_count_ratio(load_averages)
        result
      end

      private

      def read_load_averages
        if File.exist?("/proc/loadavg")
          values = File.read("/proc/loadavg").split.first(3).map(&:to_f)
          return values if values.length == 3
        end

        if (uptime_output = run_command("uptime"))
          match = uptime_output.match(/load averages?:\s+([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)/i)
          return match[1..3].map(&:to_f) if match
        end

        nil
      rescue StandardError
        nil
      end

      def check_load_average(load_averages)
        one_min = load_averages[0]

        if one_min >= @critical_threshold
          result.add_error(
            "System load average is critically high: #{one_min} (threshold: #{@critical_threshold})"
          )
        elsif one_min >= @warning_threshold
          result.add_warning(
            "System load average is elevated: #{one_min} (threshold: #{@warning_threshold})"
          )
        else
          result.add_info("System load average is normal: #{one_min}")
        end
      end

      def check_cpu_count_ratio(load_averages)
        cpu_count = detect_cpu_count
        return unless cpu_count && cpu_count > 0

        one_min = load_averages[0]
        ratio = one_min / cpu_count.to_f

        if ratio > 1.0
          result.add_warning(
            "Load average (#{one_min}) exceeds CPU count (#{cpu_count}); ratio: #{ratio.round(2)}"
          )
        else
          result.add_info("Load/CPU ratio is healthy: #{ratio.round(2)} (#{cpu_count} CPUs)")
        end
      end

      def detect_cpu_count
        if File.exist?("/proc/cpuinfo")
          File.read("/proc/cpuinfo").scan(/^processor\s*:/).count
        elsif (nproc = run_command("nproc"))
          nproc.strip.to_i
        end
      rescue StandardError
        nil
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
