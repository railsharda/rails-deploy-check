# frozen_string_literal: true

module RailsDeployCheck
  module Checks
    class DockerfileCheck
      def initialize(options = {})
        @app_path = options.fetch(:app_path, Dir.pwd)
        @required_instructions = options.fetch(:required_instructions, %w[FROM RUN CMD])
      end

      def run
        result = Result.new(name: "Dockerfile")

        check_dockerfile_exists(result)
        check_required_instructions(result)
        check_no_root_user(result)
        check_expose_instruction(result)

        result
      end

      private

      def check_dockerfile_exists(result)
        if File.exist?(dockerfile_path)
          result.add_info("Dockerfile found at #{dockerfile_path}")
        else
          result.add_error("Dockerfile not found at #{dockerfile_path}")
        end
      end

      def check_required_instructions(result)
        return unless File.exist?(dockerfile_path)

        content = File.read(dockerfile_path)
        @required_instructions.each do |instruction|
          if content.match?(/^#{instruction}\b/i)
            result.add_info("Dockerfile contains #{instruction} instruction")
          else
            result.add_warning("Dockerfile is missing #{instruction} instruction")
          end
        end
      end

      def check_no_root_user(result)
        return unless File.exist?(dockerfile_path)

        content = File.read(dockerfile_path)
        if content.match?(/^USER\s+root/i)
          result.add_warning("Dockerfile runs as root user; consider using a non-root user for security")
        elsif content.match?(/^USER\b/i)
          result.add_info("Dockerfile specifies a non-root USER")
        else
          result.add_warning("Dockerfile does not specify a USER; defaults to root")
        end
      end

      def check_expose_instruction(result)
        return unless File.exist?(dockerfile_path)

        content = File.read(dockerfile_path)
        if content.match?(/^EXPOSE\b/i)
          result.add_info("Dockerfile contains EXPOSE instruction")
        else
          result.add_warning("Dockerfile is missing EXPOSE instruction; consider documenting the port")
        end
      end

      def dockerfile_path
        File.join(@app_path, "Dockerfile")
      end
    end
  end
end
