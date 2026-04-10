module RailsDeployCheck
  module Checks
    class DockerCheck
      attr_reader :options

      def initialize(options = {})
        @options = options
        @app_path = options.fetch(:app_path, Dir.pwd)
        @required_services = options.fetch(:required_services, [])
      end

      def run
        result = Result.new(name: "Docker")

        check_dockerfile_exists(result)
        check_docker_compose_exists(result)
        check_required_services(result) if @required_services.any?
        check_env_file_referenced(result)

        result
      end

      private

      def check_dockerfile_exists(result)
        dockerfile = File.join(@app_path, "Dockerfile")
        if File.exist?(dockerfile)
          result.add_info("Dockerfile found")
        else
          result.add_warning("No Dockerfile found — Docker-based deployments may fail")
        end
      end

      def check_docker_compose_exists(result)
        candidates = ["docker-compose.yml", "docker-compose.yaml",
                      "compose.yml", "compose.yaml"]
        found = candidates.any? { |f| File.exist?(File.join(@app_path, f)) }

        if found
          result.add_info("Docker Compose file found")
          check_compose_production_override(result)
        else
          result.add_info("No Docker Compose file found (not required)")
        end
      end

      def check_compose_production_override(result)
        overrides = ["docker-compose.production.yml", "docker-compose.prod.yml"]
        found = overrides.any? { |f| File.exist?(File.join(@app_path, f)) }
        result.add_warning("No production Docker Compose override found") unless found
      end

      def check_required_services(result)
        compose_file = ["docker-compose.yml", "docker-compose.yaml",
                        "compose.yml", "compose.yaml"]
                       .map { |f| File.join(@app_path, f) }
                       .find { |f| File.exist?(f) }

        return result.add_warning("Cannot verify required services — no Compose file found") unless compose_file

        content = File.read(compose_file)
        @required_services.each do |service|
          if content.match?(/^\s+#{Regexp.escape(service)}:/)
            result.add_info("Required service '#{service}' defined in Compose file")
          else
            result.add_error("Required service '#{service}' not found in Compose file")
          end
        end
      end

      def check_env_file_referenced(result)
        dockerignore = File.join(@app_path, ".dockerignore")
        if File.exist?(dockerignore)
          content = File.read(dockerignore)
          if content.include?(".env")
            result.add_info(".env files excluded via .dockerignore")
          else
            result.add_warning(".dockerignore exists but does not exclude .env files")
          end
        else
          result.add_warning("No .dockerignore found — sensitive files may be included in Docker image")
        end
      end
    end
  end
end
