# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class BundlerAuditCheck
      AUDIT_COMMAND = "bundle-audit check --update"
      BUNDLER_AUDIT_GEM = "bundler-audit"

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @fail_on_warnings = options.fetch(:fail_on_warnings, false)
      end

      def run
        result = Result.new("Bundler Audit")

        unless bundler_audit_available?
          result.add_warning("bundler-audit gem is not installed; skipping vulnerability check")
          return result
        end

        check_gemfile_lock_exists(result)
        check_vulnerabilities(result) if result.errors.empty?

        result
      end

      private

      def bundler_audit_available?
        system("gem list #{BUNDLER_AUDIT_GEM} -i > /dev/null 2>&1")
      end

      def check_gemfile_lock_exists(result)
        lockfile = File.join(@app_path, "Gemfile.lock")
        unless File.exist?(lockfile)
          result.add_error("Gemfile.lock not found at #{lockfile}; cannot run audit")
        end
      end

      def check_vulnerabilities(result)
        output, status = run_audit_command

        if status == 0
          result.add_info("No known vulnerabilities found in dependencies")
        elsif status == 1
          parse_audit_output(output, result)
        else
          result.add_warning("bundle-audit exited with unexpected status #{status}")
        end
      end

      def run_audit_command
        Dir.chdir(@app_path) do
          output = `#{AUDIT_COMMAND} 2>&1`
          [output, $?.exitstatus]
        end
      rescue => e
        ["", 2]
      end

      def parse_audit_output(output, result)
        lines = output.lines
        vulnerabilities = lines.select { |l| l.strip.start_with?("Name:") }

        if vulnerabilities.any?
          count = vulnerabilities.size
          msg = "#{count} vulnerable gem(s) found:\n#{output.strip}"
          if @fail_on_warnings
            result.add_error(msg)
          else
            result.add_warning(msg)
          end
        else
          result.add_warning("bundle-audit reported issues:\n#{output.strip}")
        end
      end
    end
  end
end
