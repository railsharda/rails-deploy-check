# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class LocaleCheck
      attr_reader :result

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @required_locales = options.fetch(:required_locales, [])
        @result = Result.new("Locale Check")
      end

      def run
        check_config_locales_directory_exists
        check_default_locale_file_exists
        check_required_locales_present
        check_no_missing_translations_file
        result
      end

      private

      def check_config_locales_directory_exists
        locales_dir = File.join(@app_path, "config", "locales")
        if Dir.exist?(locales_dir)
          result.add_info("config/locales directory exists")
        else
          result.add_warning("config/locales directory not found — i18n translations may be missing")
        end
      end

      def check_default_locale_file_exists
        locales_dir = File.join(@app_path, "config", "locales")
        return unless Dir.exist?(locales_dir)

        en_file = File.join(locales_dir, "en.yml")
        if File.exist?(en_file)
          result.add_info("Default locale file (en.yml) found")
        else
          yml_files = Dir.glob(File.join(locales_dir, "*.yml"))
          if yml_files.any?
            result.add_info("Locale files found: #{yml_files.map { |f| File.basename(f) }.join(", ")}")
          else
            result.add_warning("No locale YAML files found in config/locales")
          end
        end
      end

      def check_required_locales_present
        return if @required_locales.empty?

        locales_dir = File.join(@app_path, "config", "locales")
        missing = @required_locales.reject do |locale|
          File.exist?(File.join(locales_dir, "#{locale}.yml"))
        end

        if missing.empty?
          result.add_info("All required locales present: #{@required_locales.join(", ")}")
        else
          result.add_error("Missing required locale files: #{missing.map { |l| "#{l}.yml" }.join(", ")}")
        end
      end

      def check_no_missing_translations_file
        missing_file = File.join(@app_path, "config", "locales", "missing_translations.yml")
        if File.exist?(missing_file)
          result.add_warning("missing_translations.yml found — untranslated keys may exist in production")
        else
          result.add_info("No missing_translations.yml file detected")
        end
      end
    end
  end
end
