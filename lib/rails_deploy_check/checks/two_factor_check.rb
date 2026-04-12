# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class TwoFactorCheck
      attr_reader :result

      def initialize(app_path: Dir.pwd, env: ENV)
        @app_path = app_path
        @env = env
        @result = Result.new("Two-Factor / OTP Configuration")
      end

      def run
        check_devise_two_factor_or_rotp_present
        check_otp_secret_key_present
        check_otp_initializer_exists
        result
      end

      private

      def check_devise_two_factor_or_rotp_present
        lockfile = File.join(@app_path, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found; cannot verify 2FA gem presence")
          return
        end

        content = File.read(lockfile)
        has_devise_two_factor = content.match?(/devise-two-factor/i)
        has_rotp = content.match?(/\brotp\b/i)

        if has_devise_two_factor || has_rotp
          result.add_info("2FA gem detected in Gemfile.lock (#{has_devise_two_factor ? 'devise-two-factor' : 'rotp'})")
        else
          result.add_info("No 2FA gem detected in Gemfile.lock; skipping further 2FA checks")
        end
      end

      def check_otp_secret_key_present
        key = @env["OTP_SECRET_KEY"] || @env["ROTP_SECRET"] || @env["TWO_FACTOR_SECRET"]
        if key && !key.strip.empty?
          result.add_info("OTP secret key environment variable is set")
        else
          result.add_warning("No OTP secret key environment variable found (OTP_SECRET_KEY, ROTP_SECRET, or TWO_FACTOR_SECRET)")
        end
      end

      def check_otp_initializer_exists
        initializer_paths = [
          File.join(@app_path, "config", "initializers", "devise_two_factor.rb"),
          File.join(@app_path, "config", "initializers", "two_factor.rb"),
          File.join(@app_path, "config", "initializers", "rotp.rb")
        ]

        found = initializer_paths.find { |p| File.exist?(p) }
        if found
          result.add_info("2FA initializer found: #{File.basename(found)}")
        else
          result.add_warning("No 2FA initializer found in config/initializers/")
        end
      end
    end
  end
end
