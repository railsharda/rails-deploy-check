module RailsDeployCheck
  module Checks
    class HeadersCheck
      SECURITY_HEADERS = {
        "X-Frame-Options"           => "Prevents clickjacking attacks",
        "X-Content-Type-Options"    => "Prevents MIME-type sniffing",
        "X-XSS-Protection"          => "Enables XSS filtering",
        "Strict-Transport-Security" => "Enforces HTTPS connections",
        "Content-Security-Policy"   => "Controls resource loading"
      }.freeze

      RECOMMENDED_INITIALIZER_PATTERNS = [
        /secure_headers/i,
        /content.security.policy/i,
        /X-Frame-Options/,
        /X-Content-Type-Options/
      ].freeze

      def initialize(options = {})
        @app_path   = options.fetch(:app_path, Dir.pwd)
        @url        = options[:url]
        @warn_only  = options.fetch(:warn_only, false)
      end

      def run
        result = Result.new("Headers Check")
        check_secure_headers_gem(result)
        check_security_initializer(result)
        check_csp_configured(result)
        check_live_headers(result) if @url
        result
      end

      private

      def check_secure_headers_gem(result)
        lockfile = File.join(@app_path, "Gemfile.lock")
        if File.exist?(lockfile)
          content = File.read(lockfile)
          if content.match?(/secure_headers/i)
            result.add_info("secure_headers gem detected in Gemfile.lock")
          else
            result.add_warning("secure_headers gem not found; consider adding it for automatic security header management")
          end
        else
          result.add_warning("Gemfile.lock not found; cannot verify secure_headers gem")
        end
      end

      def check_security_initializer(result)
        initializers_dir = File.join(@app_path, "config", "initializers")
        return result.add_warning("config/initializers directory not found") unless Dir.exist?(initializers_dir)

        files = Dir[File.join(initializers_dir, "*.rb")]
        matched = files.any? do |f|
          content = File.read(f)
          RECOMMENDED_INITIALIZER_PATTERNS.any? { |pat| content.match?(pat) }
        end

        if matched
          result.add_info("Security headers initializer detected")
        else
          msg = "No security headers initializer found in config/initializers"
          @warn_only ? result.add_warning(msg) : result.add_error(msg)
        end
      end

      def check_csp_configured(result)
        csp_file = File.join(@app_path, "config", "initializers", "content_security_policy.rb")
        if File.exist?(csp_file)
          result.add_info("Content Security Policy initializer found")
        else
          result.add_warning("config/initializers/content_security_policy.rb not found; CSP may not be configured")
        end
      end

      def check_live_headers(result)
        require "net/http"
        uri = URI.parse(@url)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
          http.head(uri.path.empty? ? "/" : uri.path)
        end
        missing = SECURITY_HEADERS.keys.reject { |h| response[h] }
        if missing.empty?
          result.add_info("All recommended security headers present on #{@url}")
        else
          missing.each do |header|
            result.add_warning("Missing security header '#{header}': #{SECURITY_HEADERS[header]}")
          end
        end
      rescue => e
        result.add_warning("Could not verify live headers for #{@url}: #{e.message}")
      end
    end
  end
end
