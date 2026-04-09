module RailsDeployCheck
  module Checks
    class RubyVersionCheck
      RUBY_VERSION_FILE = ".ruby-version"
      GEMFILE = "Gemfile"

      def initialize(app_path: Dir.pwd)
        @app_path = app_path
      end

      def run
        result = Result.new(name: "Ruby Version Check")

        check_ruby_version_file(result)
        check_gemfile_ruby_directive(result)
        check_version_mismatch(result)

        result
      end

      private

      def check_ruby_version_file(result)
        path = File.join(@app_path, RUBY_VERSION_FILE)
        unless File.exist?(path)
          result.add_warning("No .ruby-version file found in #{@app_path}")
          return
        end
        result.add_info(".ruby-version file found: #{read_ruby_version_file.strip}")
      end

      def check_gemfile_ruby_directive(result)
        path = File.join(@app_path, GEMFILE)
        unless File.exist?(path)
          result.add_error("Gemfile not found in #{@app_path}")
          return
        end

        content = File.read(path)
        if content.match?(/^\s*ruby\s+['"]\d+\.\d+/)
          result.add_info("Gemfile contains a ruby version directive")
        else
          result.add_warning("Gemfile does not specify a ruby version directive")
        end
      end

      def check_version_mismatch(result)
        ruby_version_file_path = File.join(@app_path, RUBY_VERSION_FILE)
        gemfile_path = File.join(@app_path, GEMFILE)

        return unless File.exist?(ruby_version_file_path) && File.exist?(gemfile_path)

        file_version = read_ruby_version_file.strip.sub(/^ruby-/, "")
        gemfile_content = File.read(gemfile_path)
        gemfile_match = gemfile_content.match(/^\s*ruby\s+['"]([\d.]+)['"]/) 

        return unless gemfile_match

        gemfile_version = gemfile_match[1]
        if file_version.start_with?(gemfile_version) || gemfile_version.start_with?(file_version)
          result.add_info(".ruby-version and Gemfile versions are consistent")
        else
          result.add_error(
            "Ruby version mismatch: .ruby-version=#{file_version}, Gemfile=#{gemfile_version}"
          )
        end
      end

      def read_ruby_version_file
        File.read(File.join(@app_path, RUBY_VERSION_FILE))
      end
    end
  end
end
