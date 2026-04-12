# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class SessionCheck
      SESSION_STORES = %w[
        cookie_store
        cache_store
        active_record_store
        mem_cache_store
        redis_store
        redis_cache_store
      ].freeze

      def initialize(app_path: Dir.pwd, env: ENV)
        @app_path = app_path
        @env = env
        @result = Result.new("Session")
      end

      def run
        check_secret_key_base_present
        check_session_store_configured
        check_cookie_store_secret_rotation
        @result
      end

      private

      def check_secret_key_base_present
        secret = @env["SECRET_KEY_BASE"]

        if secret.nil? || secret.strip.empty?
          @result.add_error("SECRET_KEY_BASE environment variable is not set")
        elsif secret.length < 30
          @result.add_warning("SECRET_KEY_BASE appears too short (< 30 chars); use `rails secret` to generate one")
        else
          @result.add_info("SECRET_KEY_BASE is present")
        end
      end

      def check_session_store_configured
        initializer = File.join(@app_path, "config", "initializers", "session_store.rb")
        app_rb = File.join(@app_path, "config", "application.rb")

        if File.exist?(initializer)
          content = File.read(initializer)
          store = SESSION_STORES.find { |s| content.include?(s) }
          if store
            @result.add_info("Session store configured: #{store}")
          else
            @result.add_warning("session_store.rb exists but no recognized session store found")
          end
        elsif File.exist?(app_rb) && File.read(app_rb).include?("session_store")
          @result.add_info("Session store configured in application.rb")
        else
          @result.add_warning("No explicit session store configuration found; Rails will use default cookie_store")
        end
      end

      def check_cookie_store_secret_rotation
        initializer = File.join(@app_path, "config", "initializers", "session_store.rb")
        return unless File.exist?(initializer)

        content = File.read(initializer)
        return unless content.include?("cookie_store")

        if content.include?("rotate") || content.include?("secret_key_base_older")
          @result.add_info("Cookie store secret rotation appears to be configured")
        else
          @result.add_warning("Consider configuring secret rotation for cookie store to support zero-downtime key changes")
        end
      end
    end
  end
end
