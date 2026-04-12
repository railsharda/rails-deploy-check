# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class SprocketsCheck
      def initialize(options = {})
        @app_path = options[:app_path] || Dir.pwd
        @check_digest = options.fetch(:check_digest, true)
      end

      def run
        result = Result.new(name: "Sprockets / Asset Pipeline")

        check_sprockets_gem_available(result)
        check_assets_precompiled(result)
        check_manifest_digest(result) if @check_digest
        check_no_sass_source_in_public(result)

        result
      end

      private

      def check_sprockets_gem_available(result)
        lockfile = File.join(@app_path, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found; cannot verify sprockets gem")
          return
        end

        content = File.read(lockfile)
        if content.match?(/^\s+sprockets\s+\(/)
          result.add_info("sprockets gem is present in Gemfile.lock")
        else
          result.add_info("sprockets gem not detected; asset pipeline may not be in use")
        end
      end

      def check_assets_precompiled(result)
        manifest_dir = File.join(@app_path, "public", "assets")
        unless Dir.exist?(manifest_dir)
          result.add_warning("public/assets directory not found — assets may not have been precompiled")
          return
        end

        manifests = Dir.glob(File.join(manifest_dir, ".sprockets-manifest-*.json")) +
                    Dir.glob(File.join(manifest_dir, "manifest-*.json")) +
                    Dir.glob(File.join(manifest_dir, "manifest.json"))

        if manifests.any?
          result.add_info("Sprockets manifest found: #{File.basename(manifests.first)}")
        else
          result.add_error("No Sprockets manifest found in public/assets — run 'rake assets:precompile'")
        end
      end

      def check_manifest_digest(result)
        manifest_dir = File.join(@app_path, "public", "assets")
        return unless Dir.exist?(manifest_dir)

        manifests = Dir.glob(File.join(manifest_dir, ".sprockets-manifest-*.json")) +
                    Dir.glob(File.join(manifest_dir, "manifest-*.json"))
        return if manifests.empty?

        begin
          require "json"
          data = JSON.parse(File.read(manifests.first))
          files = data["files"] || {}
          if files.empty?
            result.add_warning("Sprockets manifest exists but lists no compiled files")
          else
            result.add_info("Sprockets manifest references #{files.size} compiled asset(s)")
          end
        rescue JSON::ParserError
          result.add_warning("Sprockets manifest could not be parsed as JSON")
        end
      end

      def check_no_sass_source_in_public(result)
        sass_files = Dir.glob(File.join(@app_path, "public", "assets", "**", "*.{scss,sass,less}"))
        if sass_files.any?
          result.add_warning("Uncompiled stylesheet source files found in public/assets: #{sass_files.map { |f| File.basename(f) }.join(', ')}")
        end
      end
    end
  end
end
