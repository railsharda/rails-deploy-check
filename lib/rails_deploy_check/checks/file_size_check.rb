# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class FileSizeCheck
      DEFAULT_MAX_LOG_SIZE_MB = 500
      DEFAULT_MAX_DB_SIZE_MB = 5000
      DEFAULT_PATHS = [
        { path: "log", max_mb: DEFAULT_MAX_LOG_SIZE_MB, label: "Log directory" },
        { path: "db", max_mb: DEFAULT_MAX_DB_SIZE_MB, label: "DB directory" }
      ].freeze

      def initialize(options = {})
        @root = options.fetch(:root, Dir.pwd)
        @paths = options.fetch(:paths, DEFAULT_PATHS)
      end

      def run
        result = Result.new("FileSizeCheck")

        if @paths.nil? || @paths.empty?
          result.add_info("No paths configured for file size check")
          return result
        end

        @paths.each do |entry|
          check_path_size(result, entry)
        end

        result
      end

      private

      def check_path_size(result, entry)
        full_path = File.join(@root, entry[:path])
        label = entry[:label] || entry[:path]
        max_mb = entry[:max_mb]

        unless File.exist?(full_path)
          result.add_info("#{label} does not exist, skipping size check")
          return
        end

        size_mb = directory_size_mb(full_path)

        if size_mb >= max_mb
          result.add_error("#{label} exceeds #{max_mb}MB limit (current: #{size_mb.round(1)}MB)")
        elsif size_mb >= max_mb * 0.8
          result.add_warning("#{label} is approaching #{max_mb}MB limit (current: #{size_mb.round(1)}MB)")
        else
          result.add_info("#{label} size is #{size_mb.round(1)}MB (limit: #{max_mb}MB)")
        end
      end

      def directory_size_mb(path)
        if File.directory?(path)
          total_bytes = Dir.glob(File.join(path, "**", "*"))
                           .select { |f| File.file?(f) }
                           .sum { |f| File.size(f) rescue 0 }
          total_bytes / 1_048_576.0
        else
          (File.size(path) rescue 0) / 1_048_576.0
        end
      end
    end
  end
end
