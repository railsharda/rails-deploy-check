module RailsDeployCheck
  module Checks
    class SecretsCheck
      COMMON_SECRET_FILES = %w[
        config/secrets.yml
        config/credentials.yml.enc
        config/master.key
        .env
      ].freeze

      SENSITIVE_PATTERNS = [
        /secret_key_base/,
        /password/i,
        /api_key/i,
        /private_key/i
      ].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @rails_env = options.fetch(:rails_env, ENV["RAILS_ENV"] || "production")
        @check_master_key = options.fetch(:check_master_key, true)
      end

      def run
        result = Result.new("Secrets & Credentials")

        check_master_key_present(result) if @check_master_key
        check_credentials_file_exists(result)
        check_secret_key_base(result)
        check_dotenv_not_committed(result)

        result
      end

      private

      def check_master_key_present(result)
        master_key_path = File.join(@app_path, "config", "master.key")
        env_key = ENV["RAILS_MASTER_KEY"]

        if env_key && !env_key.strip.empty?
          result.add_info("RAILS_MASTER_KEY environment variable is set")
        elsif File.exist?(master_key_path)
          result.add_info("config/master.key file is present")
        else
          result.add_error("No master key found: set RAILS_MASTER_KEY env var or provide config/master.key")
        end
      end

      def check_credentials_file_exists(result)
        env_credentials = File.join(@app_path, "config", "credentials", "#{@rails_env}.yml.enc")
        default_credentials = File.join(@app_path, "config", "credentials.yml.enc")

        if File.exist?(env_credentials)
          result.add_info("Environment-specific credentials file found: config/credentials/#{@rails_env}.yml.enc")
        elsif File.exist?(default_credentials)
          result.add_info("Default credentials file found: config/credentials.yml.enc")
        else
          result.add_warning("No encrypted credentials file found; ensure secrets are configured for #{@rails_env}")
        end
      end

      def check_secret_key_base(result)
        secret_key_base = ENV["SECRET_KEY_BASE"]

        if secret_key_base && secret_key_base.length >= 30
          result.add_info("SECRET_KEY_BASE environment variable is set")
        elsif secret_key_base
          result.add_error("SECRET_KEY_BASE is set but appears too short (minimum 30 characters)")
        else
          result.add_warning("SECRET_KEY_BASE not set as environment variable; ensure it is available via credentials")
        end
      end

      def check_dotenv_not_committed(result)
        dotenv_path = File.join(@app_path, ".env")
        gitignore_path = File.join(@app_path, ".gitignore")

        return unless File.exist?(dotenv_path)

        if File.exist?(gitignore_path)
          ignored = File.readlines(gitignore_path).any? { |line| line.strip == ".env" }
          unless ignored
            result.add_warning(".env file exists but is not listed in .gitignore — risk of committing secrets")
          end
        else
          result.add_warning(".env file exists but no .gitignore found — risk of committing secrets")
        end
      end
    end
  end
end
