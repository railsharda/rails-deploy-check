module RailsDeployCheck
  module Checks
    class CspCheck
      def initialize(options = {})
        @app_path = options[:app_path] || Dir.pwd
        @rails_env = options[:rails_env] || ENV["RAILS_ENV"] || "production"
      end

      def run
        result = Result.new("CSP Check")

        check_secure_headers_or_csp_gem(result)
        check_csp_initializer_exists(result)
        check_no_unsafe_inline_in_production(result)

        result
      end

      private

      def check_secure_headers_or_csp_gem(result)
        lockfile = File.join(@app_path, "Gemfile.lock")

        unless File.exist?(lockfile)
          result.add_warning("Gemfile.lock not found; cannot verify CSP gem presence")
          return
        end

        content = File.read(lockfile)
        has_secure_headers = content.match?(/^\s+secure_headers\s/)
        has_csp = content.match?(/^\s+content_security_policy\s/) || content.match?(/^\s+csp-rails\s/)

        if has_secure_headers
          result.add_info("secure_headers gem found in Gemfile.lock")
        elsif has_csp
          result.add_info("CSP gem found in Gemfile.lock")
        else
          result.add_warning("No CSP gem (secure_headers, content_security_policy) found in Gemfile.lock")
        end
      end

      def check_csp_initializer_exists(result)
        initializers_dir = File.join(@app_path, "config", "initializers")
        csp_files = ["content_security_policy.rb", "secure_headers.rb", "csp.rb"]

        found = csp_files.any? do |f|
          File.exist?(File.join(initializers_dir, f))
        end

        if found
          result.add_info("CSP initializer found in config/initializers")
        else
          csp_in_application = check_csp_in_application_config
          if csp_in_application
            result.add_info("CSP configuration found in application config")
          else
            result.add_warning("No CSP initializer found; consider adding a Content Security Policy")
          end
        end
      end

      def check_no_unsafe_inline_in_production(result)
        return unless @rails_env == "production"

        initializers_dir = File.join(@app_path, "config", "initializers")
        csp_files = Dir.glob(File.join(initializers_dir, "*.rb"))
        app_config = File.join(@app_path, "config", "application.rb")
        csp_files << app_config if File.exist?(app_config)

        csp_files.each do |file|
          next unless File.exist?(file)
          content = File.read(file)
          if content.include?("unsafe-inline") || content.include?(":unsafe_inline")
            result.add_warning("'unsafe-inline' detected in #{File.basename(file)}; this weakens CSP in production")
            return
          end
        end

        result.add_info("No 'unsafe-inline' directive detected in CSP configuration")
      end

      def check_csp_in_application_config
        app_config = File.join(@app_path, "config", "application.rb")
        return false unless File.exist?(app_config)
        File.read(app_config).include?("content_security_policy")
      end
    end
  end
end
