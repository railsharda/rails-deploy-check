module RailsDeployCheck
  module Checks
    class HttpCheck
      DEFAULT_TIMEOUT = 10
      SUCCESS_CODES = (200..399).freeze

      def initialize(config = {})
        @app_url    = config[:app_url]
        @timeout    = config[:timeout] || DEFAULT_TIMEOUT
        @endpoints  = config[:endpoints] || ["/"]
        @result     = Result.new("HTTP Check")
      end

      def run
        if @app_url.nil? || @app_url.strip.empty?
          @result.add_warning("APP_URL not configured — skipping HTTP reachability check")
          return @result
        end

        @endpoints.each { |path| check_endpoint(path) }
        @result
      end

      private

      def check_endpoint(path)
        uri = build_uri(path)
        response = perform_request(uri)

        if SUCCESS_CODES.cover?(response.code.to_i)
          @result.add_info("#{uri} responded with HTTP #{response.code}")
        else
          @result.add_error("#{uri} returned unexpected status HTTP #{response.code}")
        end
      rescue SocketError => e
        @result.add_error("Cannot reach #{@app_url}#{path}: #{e.message}")
      rescue Net::OpenTimeout, Net::ReadTimeout
        @result.add_error("Request to #{@app_url}#{path} timed out after #{@timeout}s")
      rescue StandardError => e
        @result.add_error("HTTP check failed for #{path}: #{e.message}")
      end

      def build_uri(path)
        base = @app_url.chomp("/")
        path = "/#{path.lstrip.delete_prefix('/')}" 
        URI.parse("#{base}#{path}")
      end

      def perform_request(uri)
        require "net/http"
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @timeout
        http.read_timeout = @timeout
        http.get(uri.request_uri)
      end
    end
  end
end
