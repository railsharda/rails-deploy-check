# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    module TwoFactorCheckIntegration
      def self.build(app_path: Dir.pwd, env: ENV)
        TwoFactorCheck.new(app_path: app_path, env: env)
      end

      def self.register(registry, app_path: Dir.pwd, env: ENV)
        return unless applicable?(app_path: app_path, env: env)

        registry << build(app_path: app_path, env: env)
      end

      def self.applicable?(app_path: Dir.pwd, env: ENV)
        two_factor_gem_in_lockfile?(app_path) ||
          otp_secret_env_present?(env) ||
          two_factor_initializer_present?(app_path)
      end

      def self.two_factor_gem_in_lockfile?(app_path)
        lockfile = File.join(app_path, "Gemfile.lock")
        return false unless File.exist?(lockfile)

        content = File.read(lockfile)
        content.match?(/devise-two-factor/i) || content.match?(/\brotp\b/i)
      end

      def self.otp_secret_env_present?(env)
        %w[OTP_SECRET_KEY ROTP_SECRET TWO_FACTOR_SECRET].any? do |key|
          env[key] && !env[key].strip.empty?
        end
      end

      def self.two_factor_initializer_present?(app_path)
        [
          "config/initializers/devise_two_factor.rb",
          "config/initializers/two_factor.rb",
          "config/initializers/rotp.rb"
        ].any? { |rel| File.exist?(File.join(app_path, rel)) }
      end
    end
  end
end
