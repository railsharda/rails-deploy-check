module RailsDeployCheck
  module Checks
    class SslCheck
      DEFAULT_TIMEOUT = 5
      WARN_EXPIRY_DAYS = 30
      CRITICAL_EXPIRY_DAYS = 7

      def initialize(config = {})
        @host = config[:host]
        @port = config[:port] || 443
        @timeout = config[:timeout] || DEFAULT_TIMEOUT
        @warn_days = config[:warn_expiry_days] || WARN_EXPIRY_DAYS
        @critical_days = config[:critical_expiry_days] || CRITICAL_EXPIRY_DAYS
      end

      def run
        result = Result.new("SSL Check")

        check_host_configured(result)
        return result unless result.errors.empty?

        check_ssl_certificate(result)
        result
      end

      private

      def check_host_configured(result)
        if @host.nil? || @host.to_s.strip.empty?
          result.add_error("No host configured for SSL check. Set config.ssl_host in your deploy check configuration.")
        end
      end

      def check_ssl_certificate(result)
        require "openssl"
        require "socket"

        cert = fetch_certificate
        return result.add_error("Could not retrieve SSL certificate from #{@host}:#{@port}") if cert.nil?

        check_certificate_expiry(result, cert)
        check_certificate_hostname(result, cert)
      rescue SocketError => e
        result.add_error("Could not connect to #{@host}:#{@port} — #{e.message}")
      rescue OpenSSL::SSL::SSLError => e
        result.add_error("SSL error on #{@host}:#{@port} — #{e.message}")
      rescue Errno::ECONNREFUSED
        result.add_error("Connection refused to #{@host}:#{@port}")
      rescue Errno::ETIMEDOUT
        result.add_error("Connection timed out to #{@host}:#{@port}")
      end

      def fetch_certificate
        tcp = Socket.tcp(@host, @port, connect_timeout: @timeout)
        ssl_ctx = OpenSSL::SSL::SSLContext.new
        ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
        ssl_ctx.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)

        ssl = OpenSSL::SSL::SSLSocket.new(tcp, ssl_ctx)
        ssl.hostname = @host
        ssl.connect
        cert = ssl.peer_cert
        ssl.close
        tcp.close
        cert
      end

      def check_certificate_expiry(result, cert)
        expiry = cert.not_after
        days_remaining = ((expiry - Time.now) / 86_400).floor

        if days_remaining <= 0
          result.add_error("SSL certificate for #{@host} has expired (expired #{expiry})")
        elsif days_remaining <= @critical_days
          result.add_error("SSL certificate for #{@host} expires in #{days_remaining} day(s) (#{expiry})")
        elsif days_remaining <= @warn_days
          result.add_warning("SSL certificate for #{@host} expires in #{days_remaining} day(s) (#{expiry})")
        else
          result.add_info("SSL certificate for #{@host} is valid for #{days_remaining} more day(s) (expires #{expiry})")
        end
      end

      def check_certificate_hostname(result, cert)
        ssl_ctx = OpenSSL::SSL::SSLContext.new
        unless OpenSSL::SSL.verify_certificate_identity(cert, @host)
          result.add_error("SSL certificate hostname mismatch: certificate is not valid for #{@host}")
        end
      end
    end
  end
end
