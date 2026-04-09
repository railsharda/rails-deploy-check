module RailsDeployCheck
  module Checks
    class EnvironmentCheck
      DEFAULT_REQUIRED_VARS = %w[
        SECRET_KEY_BASE
        DATABASE_URL
        RAILS_ENV
      ].freeze

      def initialize(config = {})
        @config = config
        @required_vars = Array(config[:required_env_vars]) + DEFAULT_REQUIRED_VARS
        @required_vars.uniq!
        @env_source = config[:env_source] || ENV
      end

      def run
        result = Result.new(name: "Environment Check")

        check_required_variables(result)
        check_rails_env(result)
        check_secret_key_base(result)

        result
      end

      private

      def check_required_variables(result)
        missing = @required_vars.select do |var|
          val = @env_source[var]
          val.nil? || val.strip.empty?
        end

        if missing.any?
          missing.each do |var|
            result.add_error("Required environment variable not set: #{var}")
          end
        else
          result.add_info("All #{@required_vars.size} required environment variables are set.")
        end
      end

      def check_rails_env(result)
        rails_env = @env_source["RAILS_ENV"]

        return if rails_env.nil?

        if rails_env == "development"
          result.add_warning("RAILS_ENV is set to 'development'. Expected 'production' for deployment.")
        elsif rails_env == "test"
          result.add_error("RAILS_ENV is set to 'test'. This should not be deployed.")
        else
          result.add_info("RAILS_ENV is set to '#{rails_env}'.")
        end
      end

      def check_secret_key_base(result)
        secret = @env_source["SECRET_KEY_BASE"]
        return if secret.nil?

        if secret.length < 30
          result.add_warning("SECRET_KEY_BASE appears too short. Ensure it is a strong random value.")
        end
      end
    end
  end
end
