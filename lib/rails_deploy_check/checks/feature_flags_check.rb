# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class FeatureFlagsCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @required_flags = Array(options[:required_flags])
        @flipper_enabled = options.fetch(:flipper_enabled, nil)
      end

      def run
        result = Result.new(name: "Feature Flags")

        check_flipper_gem_available(result)
        check_flipper_initializer_exists(result)
        check_required_flags_defined(result) if @required_flags.any?

        result
      end

      private

      def check_flipper_gem_available(result)
        lockfile = File.join(@app_path, "Gemfile.lock")

        unless File.exist?(lockfile)
          result.add_info("Gemfile.lock not found; skipping Flipper gem check")
          return
        end

        content = File.read(lockfile)
        if content.match?(/^\s+flipper/)
          result.add_info("Flipper gem detected in Gemfile.lock")
        else
          result.add_info("Flipper gem not found — feature flags check skipped")
        end
      end

      def check_flipper_initializer_exists(result)
        initializer = File.join(@app_path, "config", "initializers", "flipper.rb")
        flipper_yml = File.join(@app_path, "config", "flipper.yml")

        if File.exist?(initializer)
          result.add_info("Flipper initializer found at config/initializers/flipper.rb")
        elsif File.exist?(flipper_yml)
          result.add_info("Flipper config found at config/flipper.yml")
        else
          lockfile = File.join(@app_path, "Gemfile.lock")
          if File.exist?(lockfile) && File.read(lockfile).match?(/^\s+flipper/)
            result.add_warning("Flipper gem present but no initializer or config file found")
          end
        end
      end

      def check_required_flags_defined(result)
        initializer = File.join(@app_path, "config", "initializers", "flipper.rb")

        unless File.exist?(initializer)
          result.add_warning("Cannot verify required feature flags — initializer not found")
          return
        end

        content = File.read(initializer)
        missing = @required_flags.reject { |flag| content.include?(flag.to_s) }

        if missing.empty?
          result.add_info("All required feature flags are referenced in Flipper initializer")
        else
          missing.each do |flag|
            result.add_warning("Required feature flag '#{flag}' not found in Flipper initializer")
          end
        end
      end
    end
  end
end
