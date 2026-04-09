module RailsDeployCheck
  module Checks
    class DiskSpaceCheck
      DEFAULT_MIN_FREE_MB = 500
      DEFAULT_PATHS = ["/", "tmp", "log", "public/assets"].freeze

      def initialize(config = {})
        @min_free_mb = config.fetch(:min_free_mb, DEFAULT_MIN_FREE_MB)
        @paths = config.fetch(:paths, DEFAULT_PATHS)
        @app_root = config.fetch(:app_root, Dir.pwd)
      end

      def run
        result = Result.new("Disk Space")

        @paths.each do |path|
          full_path = resolve_path(path)
          check_path_disk_space(result, full_path)
        end

        result
      end

      private

      def resolve_path(path)
        return path if path.start_with?("/")

        File.join(@app_root, path)
      end

      def check_path_disk_space(result, path)
        unless File.exist?(path)
          result.add_warning("Path does not exist, skipping disk space check: #{path}")
          return
        end

        free_mb = available_mb(path)

        if free_mb.nil?
          result.add_warning("Could not determine disk space for: #{path}")
          return
        end

        if free_mb < @min_free_mb
          result.add_error(
            "Low disk space on #{path}: #{free_mb}MB free (minimum: #{@min_free_mb}MB)"
          )
        else
          result.add_info("Disk space OK on #{path}: #{free_mb}MB free")
        end
      end

      def available_mb(path)
        output = `df -m #{Shellwords.escape(path)} 2>/dev/null`
        return nil unless $?.success?

        lines = output.strip.split("\n")
        return nil if lines.size < 2

        parts = lines.last.split
        return nil if parts.size < 4

        parts[3].to_i
      rescue => e
        nil
      end
    end
  end
end
