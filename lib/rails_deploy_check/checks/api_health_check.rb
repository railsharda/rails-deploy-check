module RailsDeployCheck
  module Checks
    class ApiHealthCheck
      def initialize(options = {})
        @url = options[:url] || ENV['API_HEALTH_URL']
        @timeout = options[:timeout] || 5
        @expected_status = options[:expected_status] || 200
        @headers = options[:headers] || {}
      end

      def run
        result = Result.new('API Health Check')

        check_url_configured(result)
        return result unless @url

        check_url_format(result)
        return result unless valid_url?

        check_endpoint_reachable(result)
        result
      end

      private

      def check_url_configured(result)
        if @url.nil? || @url.strip.empty?
          result.add_warning('No API health URL configured (set API_HEALTH_URL or pass :url option)')
        else
          result.add_info("API health URL configured: #{@url}")
        end
      end

      def check_url_format(result)
        uri = URI.parse(@url)
        unless %w[http https].include?(uri.scheme)
          result.add_error("API health URL has invalid scheme: #{uri.scheme}. Must be http or https.")
        end
      rescue URI::InvalidURIError
        result.add_error("API health URL is not a valid URI: #{@url}")
      end

      def check_endpoint_reachable(result)
        uri = URI.parse(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = @timeout
        http.read_timeout = @timeout

        request = Net::HTTP::Get.new(uri.request_uri)
        @headers.each { |k, v| request[k] = v }

        response = http.request(request)

        if response.code.to_i == @expected_status
          result.add_info("API health endpoint responded with #{response.code}")
        else
          result.add_error("API health endpoint returned #{response.code}, expected #{@expected_status}")
        end
      rescue Net::OpenTimeout, Net::ReadTimeout
        result.add_error("API health endpoint timed out after #{@timeout}s: #{@url}")
      rescue Errno::ECONNREFUSED
        result.add_error("API health endpoint connection refused: #{@url}")
      rescue StandardError => e
        result.add_error("API health endpoint check failed: #{e.message}")
      end

      def valid_url?
        uri = URI.parse(@url.to_s)
        %w[http https].include?(uri.scheme) && !uri.host.nil?
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
