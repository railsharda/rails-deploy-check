module RailsDeployCheck
  module Checks
    class LogCheck
      LOG_SIZE_WARNING_MB = 500
      LOG_SIZE_ERROR_MB = 1000

      def initialize(options = {})
        @app_path = options[:app_path] || Dir.pwd
        @log_dir = options[:log_dir] || File.join(@app_path, "log")
        @rails_env = options[:rails_env] || ENV["RAILS_ENV"] || "production"
        @size_warning_mb = options[:size_warning_mb] || LOG_SIZE_WARNING_MB
        @size_error_mb = options[:size_error_mb] || LOG_SIZE_ERROR_MB
      end

      def run
        result = Result.new("Log Files")
        check_log_directory_exists(result)
        check_log_file_size(result)
        check_log_directory_writable(result)
        result
      end

      private

      def check_log_directory_exists(result)
        if Dir.exist?(@log_dir)
          result.add_info("Log directory exists: #{@log_dir}")
        else
          result.add_warning("Log directory not found: #{@log_dir}. It will be created on first run.")
        end
      end

      def check_log_file_size(result)
        log_file = File.join(@log_dir, "#{@rails_env}.log")
        return unless File.exist?(log_file)

        size_mb = File.size(log_file) / (1024.0 * 1024.0)
        size_str = format("%.1f MB", size_mb)

        if size_mb >= @size_error_mb
          result.add_error("Log file is very large (#{size_str}): #{log_file}. Consider rotating before deploy.")
        elsif size_mb >= @size_warning_mb
          result.add_warning("Log file is large (#{size_str}): #{log_file}. Consider rotating before deploy.")
        else
          result.add_info("Log file size is acceptable (#{size_str}): #{log_file}")
        end
      end

      def check_log_directory_writable(result)
        target = Dir.exist?(@log_dir) ? @log_dir : File.dirname(@log_dir)
        if File.writable?(target)
          result.add_info("Log directory is writable")
        else
          result.add_error("Log directory is not writable: #{@log_dir}. Application will not be able to write logs.")
        end
      end
    end
  end
end
