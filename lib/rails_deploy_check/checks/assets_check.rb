module RailsDeployCheck
  module Checks
    class AssetsCheck
      MANIFEST_PATTERNS = [
        "public/assets/.sprockets-manifest*.json",
        "public/assets/manifest*.json",
        "public/assets/manifest.yml"
      ].freeze

      REQUIRED_ASSET_TYPES = %w[application.css application.js].freeze

      def initialize(config = {})
        @config = config
        @app_root = config[:app_root] || Dir.pwd
      end

      def run
        result = Result.new(name: "Assets Check")

        check_manifest_exists(result)
        check_assets_compiled(result)
        check_asset_host_configured(result)

        result
      end

      private

      def check_manifest_exists(result)
        manifest_files = MANIFEST_PATTERNS.flat_map do |pattern|
          Dir.glob(File.join(@app_root, pattern))
        end

        if manifest_files.empty?
          result.add_error(
            "No asset manifest found. Run `rake assets:precompile` before deploying."
          )
        else
          result.add_info("Asset manifest found: #{File.basename(manifest_files.first)}")
        end
      end

      def check_assets_compiled(result)
        assets_dir = File.join(@app_root, "public", "assets")

        unless Dir.exist?(assets_dir)
          result.add_warning("public/assets directory does not exist. Assets may not be precompiled.")
          return
        end

        REQUIRED_ASSET_TYPES.each do |asset_type|
          pattern = File.join(assets_dir, "#{File.basename(asset_type, '.*')}-*#{File.extname(asset_type)}")
          matches = Dir.glob(pattern)

          if matches.empty?
            result.add_warning("Compiled asset not found for: #{asset_type}")
          else
            result.add_info("Compiled asset present: #{asset_type}")
          end
        end
      end

      def check_asset_host_configured(result)
        return unless @config[:check_asset_host]

        asset_host = @config[:asset_host]
        if asset_host.nil? || asset_host.to_s.strip.empty?
          result.add_warning("ASSET_HOST is not configured. CDN or asset host may be missing.")
        else
          result.add_info("Asset host configured: #{asset_host}")
        end
      end
    end
  end
end
