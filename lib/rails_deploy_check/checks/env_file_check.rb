module RailsDeployCheck
  module Checks
    class EnvFileCheck
      attr_reader :result

      def initialize(app_path: Dir.pwd, required_keys: [], warn_if_dotenv_present: true)
        @app_path = app_path
        @required_keys = required_keys
        @warn_if_dotenv_present = warn_if_dotenv_present
        @result = Result.new("EnvFileCheck")
      end

      def run
        check_dotenv_not_committed
        check_env_example_exists
        check_required_keys_in_example
        result
      end

      private

      def check_dotenv_not_committed
        dotenv_path = File.join(@app_path, ".env")
        gitignore_path = File.join(@app_path, ".gitignore")

        if File.exist?(dotenv_path)
          if @warn_if_dotenv_present
            result.add_warning(".env file exists on disk — ensure it is not committed to version control")
          end

          if File.exist?(gitignore_path)
            gitignore_content = File.read(gitignore_path)
            unless gitignore_content.match?(/^\s*\.env\s*$/)
              result.add_error(".env file is not listed in .gitignore — risk of exposing secrets")
            end
          else
            result.add_warning(".gitignore not found; cannot verify .env is excluded from version control")
          end
        else
          result.add_info(".env file not present on disk (expected in production)")
        end
      end

      def check_env_example_exists
        example_candidates = [".env.example", ".env.sample", ".env.template"]
        found = example_candidates.find { |f| File.exist?(File.join(@app_path, f)) }

        if found
          result.add_info("Environment example file found: #{found}")
          @env_example_path = File.join(@app_path, found)
        else
          result.add_warning("No .env.example / .env.sample / .env.template found — consider adding one for documentation")
        end
      end

      def check_required_keys_in_example
        return if @required_keys.empty?
        return unless @env_example_path && File.exist?(@env_example_path)

        example_keys = parse_keys(@env_example_path)
        missing = @required_keys - example_keys

        if missing.empty?
          result.add_info("All required keys are documented in the env example file")
        else
          missing.each do |key|
            result.add_warning("Required env key '#{key}' is not documented in the env example file")
          end
        end
      end

      def parse_keys(file_path)
        File.readlines(file_path).filter_map do |line|
          stripped = line.strip
          next if stripped.empty? || stripped.start_with?("#")
          stripped.split("=", 2).first&.strip
        end
      end
    end
  end
end
