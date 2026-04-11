# frozen_string_literal: true

require "open3"

module RailsDeployCheck
  module Checks
    class SwapCheck
      DEFAULT_MIN_SWAP_MB = 512
      DEFAULT_WARN_SWAP_MB = 1024

      attr_reader :config

      def initialize(config = {})
        @config = config
      end

      def run
        result = Result.new(name: "Swap Space")

        check_swap_available(result)
        check_swap_usage(result)

        result
      end

      private

      def check_swap_available(result)
        total = total_swap_mb

        if total.nil?
          result.add_warning("Could not determine swap space (unsupported platform or missing command)")
          return
        end

        min_mb = config.fetch(:min_swap_mb, DEFAULT_MIN_SWAP_MB)

        if total == 0
          result.add_warning("No swap space configured. Consider adding swap for memory safety during deploys.")
        elsif total < min_mb
          result.add_warning("Swap space is low: #{total}MB available (recommended: #{min_mb}MB)")
        else
          result.add_info("Swap space available: #{total}MB")
        end
      end

      def check_swap_usage(result)
        used = used_swap_mb
        total = total_swap_mb

        return if used.nil? || total.nil? || total == 0

        warn_mb = config.fetch(:warn_used_swap_mb, DEFAULT_WARN_SWAP_MB)
        usage_pct = (used.to_f / total * 100).round(1)

        if used > warn_mb
          result.add_warning("High swap usage: #{used}MB used of #{total}MB (#{usage_pct}%)")
        else
          result.add_info("Swap usage: #{used}MB / #{total}MB (#{usage_pct}%)")
        end
      end

      def swap_info
        @swap_info ||= begin
          stdout, _stderr, status = Open3.capture3("free -m")
          return nil unless status.success?

          swap_line = stdout.lines.find { |l| l.strip.start_with?("Swap:") }
          return nil unless swap_line

          parts = swap_line.split
          { total: parts[1].to_i, used: parts[2].to_i, free: parts[3].to_i }
        rescue Errno::ENOENT
          nil
        end
      end

      def total_swap_mb
        swap_info&.dig(:total)
      end

      def used_swap_mb
        swap_info&.dig(:used)
      end
    end
  end
end
