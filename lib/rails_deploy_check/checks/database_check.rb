module RailsDeployCheck
  module Checks
    class DatabaseCheck
      def initialize(config = {})
        @config = config
        @result = Result.new('Database Check')
      end

      def run
        check_database_connection
        check_database_exists
        check_connection_pool
        @result
      end

      private

      def check_database_connection
        return unless defined?(ActiveRecord::Base)

        begin
          ActiveRecord::Base.connection.active?
          @result.add_info('Database connection is active')
        rescue ActiveRecord::NoDatabaseError => e
          @result.add_error("Database does not exist: #{e.message}")
        rescue ActiveRecord::ConnectionNotEstablished => e
          @result.add_error("Cannot establish database connection: #{e.message}")
        rescue StandardError => e
          @result.add_error("Database connection failed: #{e.message}")
        end
      end

      def check_database_exists
        return unless defined?(ActiveRecord::Base)

        begin
          tables = ActiveRecord::Base.connection.tables
          if tables.empty?
            @result.add_warning('Database exists but contains no tables — migrations may not have run')
          else
            @result.add_info("Database reachable with #{tables.size} table(s)")
          end
        rescue StandardError
          # already reported in check_database_connection
        end
      end

      def check_connection_pool
        return unless defined?(ActiveRecord::Base)

        begin
          pool = ActiveRecord::Base.connection_pool
          size = pool.size
          checked_out = pool.connections.count(&:in_use?) rescue 0

          if size < 2
            @result.add_warning("Connection pool size is #{size}, which may be too small for production")
          else
            @result.add_info("Connection pool size: #{size} (#{checked_out} in use)")
          end
        rescue StandardError => e
          @result.add_warning("Could not inspect connection pool: #{e.message}")
        end
      end
    end
  end
end
