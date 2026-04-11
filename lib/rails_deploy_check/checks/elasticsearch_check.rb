# frozen_string_literal: true

require "uri"
require "net/http"

module RailsDeployCheck
  module Checks
    class ElasticsearchCheck
      KNOWN_PORTS = [9200, 9243].freeze
      DEFAULT_TIMEOUT = 5

      def initialize(config = {})
        @url = config[:url] || ENV["ELASTICSEARCH_URL"] || ENV["BONSAI_URL"] || ENV["SEARCHBOX_URL"]
        @timeout = config[:timeout] || DEFAULT_TIMEOUT
        @required = config.fetch(:required, false)
      end

      def run
        result = Result.new("ElasticsearchCheck")

        unless @url
          if @required
            result.add_error("No Elasticsearch URL configured (ELASTICSEARCH_URL, BONSAI_URL, or SEARCHBOX_URL)")
          else
            result.add_info("Elasticsearch URL not configured — skipping check")
          end
          return result
        end

        check_url_format(result)
        check_port_known(result)
        check_elasticsearch_reachable(result)

        result
      end

      private

      def check_url_format(result)
        uri = URI.parse(@url)
        unless uri.scheme&.match?(/\Ahttps?\z/) && uri.host
          result.add_error("Elasticsearch URL is not a valid HTTP/HTTPS URI: #{@url}")
        end
      rescue URI::InvalidURIError
        result.add_error("Elasticsearch URL is malformed: #{@url}")
      end

      def check_port_known(result)
        uri = URI.parse(@url)
        port = uri.port
        return if KNOWN_PORTS.include?(port)

        result.add_warning("Elasticsearch is running on non-standard port #{port} (expected #{KNOWN_PORTS.join(' or ')})")
      rescue URI::InvalidURIError
        # already reported in check_url_format
      end

      def check_elasticsearch_reachable(result)
        uri = URI.parse(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @timeout
        http.read_timeout = @timeout

        response = http.get("/")
        if response.code.to_i == 200
          result.add_info("Elasticsearch is reachable at #{@url}")
        else
          result.add_warning("Elasticsearch returned HTTP #{response.code} at #{@url}")
        end
      rescue Errno::ECONNREFUSED
        result.add_error("Elasticsearch connection refused at #{@url}")
      rescue Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout
        result.add_error("Elasticsearch connection timed out at #{@url}")
      rescue StandardError => e
        result.add_error("Elasticsearch check failed: #{e.message}")
      end
    end
  end
end
