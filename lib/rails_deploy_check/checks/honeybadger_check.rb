# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class HoneybadgerCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @api_key = options[:api_key] || ENV["HONEYBADGER_API_KEY"]
      end

      def run
        result = Result.new(name: "Honeybadger")
        check_api_key_present(result)
        check_gem_in_lockfile(result)
        check_initializer_exists(result)
        check_api_key_format(result)
        result
      end

      private

      def check_api_key_present(result)
        if @api_key.nil? || @api_key.strip.empty?
          result.add_error("HONEYBADGER_API_KEY environment variable is not set")
        else
          result.add_info("Honeybadger API key is configured")
        end
      end

      def check_gem_in_lockfile(result)
        lockfile = File.join(@app_path, "Gemfile.lock")
        return result.add_warning("Gemfile.lock not found; cannot verify honeybadger gem") unless File.exist?(lockfile)

        if File.read(lockfile).match?(/^\s+honeybadger\b/)
          result.add_info("honeybadger gem is present in Gemfile.lock")
        else
          result.add_warning("honeybadger gem not found in Gemfile.lock")
        end
      end

      def check_initializer_exists(result)
        initializer = File.join(@app_path, "config", "initializers", "honeybadger.rb")
        if File.exist?(initializer)
          result.add_info("Honeybadger initializer found at config/initializers/honeybadger.rb")
        else
          result.add_warning("Honeybadger initializer not found at config/initializers/honeybadger.rb")
        end
      end

      def check_api_key_format(result)
        return unless @api_key && !@api_key.strip.empty?

        if @api_key.match?(/\A[a-f0-9]{6,}\z/i)
          result.add_info("Honeybadger API key format looks valid")
        else
          result.add_warning("Honeybadger API key format looks unexpected (expected a hex string)")
        end
      end
    end
  end
end
