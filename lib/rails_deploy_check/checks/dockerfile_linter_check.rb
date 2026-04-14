# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class DockerfileLinterCheck
      BEST_PRACTICE_INSTRUCTIONS = %w[HEALTHCHECK USER].freeze
      INSECURE_PATTERNS = [
        /ENV\s+\S*(SECRET|PASSWORD|TOKEN|KEY)\s*=/i,
        /ARG\s+\S*(SECRET|PASSWORD|TOKEN|KEY)/i
      ].freeze

      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @dockerfile_path = options[:dockerfile_path] || File.join(@app_path, "Dockerfile")
      end

      def run
        result = Result.new(name: "Dockerfile Linter")

        unless File.exist?(@dockerfile_path)
          result.add_info("Dockerfile not found at #{@dockerfile_path}, skipping lint")
          return result
        end

        check_no_latest_tag(result)
        check_best_practice_instructions(result)
        check_no_secrets_in_env(result)
        check_non_root_user(result)

        result
      end

      private

      def dockerfile_content
        @dockerfile_content ||= File.read(@dockerfile_path)
      end

      def dockerfile_lines
        @dockerfile_lines ||= dockerfile_content.lines.map(&:strip)
      end

      def check_no_latest_tag(result)
        from_lines = dockerfile_lines.select { |l| l.match?(/^FROM\s+/i) }
        from_lines.each do |line|
          if line.match?(/^FROM\s+\S+:latest/i) || line.match?(/^FROM\s+[^:\s]+\s/i) && !line.include?(":")
            result.add_warning("Dockerfile uses 'latest' or untagged base image: #{line.strip}")
          end
        end
      end

      def check_best_practice_instructions(result)
        BEST_PRACTICE_INSTRUCTIONS.each do |instruction|
          unless dockerfile_content.match?(/^#{instruction}\s/i)
            result.add_warning("Dockerfile is missing recommended instruction: #{instruction}")
          end
        end
      end

      def check_no_secrets_in_env(result)
        INSECURE_PATTERNS.each do |pattern|
          if dockerfile_content.match?(pattern)
            result.add_error("Dockerfile may contain hardcoded secrets (matched pattern: #{pattern.source})")
          end
        end
      end

      def check_non_root_user(result)
        user_lines = dockerfile_lines.select { |l| l.match?(/^USER\s+/i) }
        if user_lines.any? { |l| l.match?(/^USER\s+root$/i) }
          result.add_warning("Dockerfile sets USER to root, which is a security risk")
        end
      end
    end
  end
end
