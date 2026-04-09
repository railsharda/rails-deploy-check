require 'spec_helper'

RSpec.describe RailsDeployCheck::Checks::DatabaseCheck do
  subject(:check) { described_class.new }

  describe '#run' do
    context 'when ActiveRecord is not defined' do
      before do
        hide_const('ActiveRecord') if defined?(ActiveRecord)
      end

      it 'returns a result without errors' do
        result = check.run
        expect(result.errors).to be_empty
      end
    end

    context 'when ActiveRecord is defined' do
      let(:connection_double) { instance_double('ActiveRecord::ConnectionAdapters::AbstractAdapter') }
      let(:pool_double) { instance_double('ActiveRecord::ConnectionAdapters::ConnectionPool') }

      before do
        stub_const('ActiveRecord::Base', Class.new)
        stub_const('ActiveRecord::NoDatabaseError', Class.new(StandardError))
        stub_const('ActiveRecord::ConnectionNotEstablished', Class.new(StandardError))

        allow(ActiveRecord::Base).to receive(:connection).and_return(connection_double)
        allow(ActiveRecord::Base).to receive(:connection_pool).and_return(pool_double)
        allow(connection_double).to receive(:active?).and_return(true)
        allow(connection_double).to receive(:tables).and_return(['users', 'posts', 'schema_migrations'])
        allow(pool_double).to receive(:size).and_return(5)
        allow(pool_double).to receive(:connections).and_return([])
      end

      it 'returns a passing result' do
        result = check.run
        expect(result.errors).to be_empty
        expect(result.warnings).to be_empty
      end

      it 'reports database connection info' do
        result = check.run
        expect(result.infos).to include(match(/Database connection is active/))
      end

      it 'reports table count' do
        result = check.run
        expect(result.infos).to include(match(/3 table/))
      end

      it 'reports connection pool size' do
        result = check.run
        expect(result.infos).to include(match(/Connection pool size: 5/))
      end

      context 'when database has no tables' do
        before do
          allow(connection_double).to receive(:tables).and_return([])
        end

        it 'adds a warning about missing tables' do
          result = check.run
          expect(result.warnings).to include(match(/contains no tables/))
        end
      end

      context 'when connection pool is too small' do
        before do
          allow(pool_double).to receive(:size).and_return(1)
        end

        it 'adds a warning about pool size' do
          result = check.run
          expect(result.warnings).to include(match(/too small for production/))
        end
      end

      context 'when database connection fails' do
        before do
          allow(connection_double).to receive(:active?)
            .and_raise(ActiveRecord::ConnectionNotEstablished, 'connection refused')
        end

        it 'adds an error to the result' do
          result = check.run
          expect(result.errors).to include(match(/Cannot establish database connection/))
        end
      end
    end
  end
end
