require 'spec_helper'
require 'rails_deploy_check/checks/api_health_check'

RSpec.describe RailsDeployCheck::Checks::ApiHealthCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe '#run' do
    context 'when no URL is configured' do
      it 'adds a warning' do
        check = build_check(url: nil)
        result = check.run
        expect(result.warnings).to include(match(/No API health URL configured/))
      end
    end

    context 'when URL has invalid scheme' do
      it 'adds an error for ftp scheme' do
        check = build_check(url: 'ftp://example.com/health')
        result = check.run
        expect(result.errors).to include(match(/invalid scheme/))
      end
    end

    context 'when URL is malformed' do
      it 'adds an error' do
        check = build_check(url: 'not a url !!!')
        result = check.run
        expect(result.errors).to include(match(/not a valid URI/))
      end
    end

    context 'when endpoint returns expected status' do
      it 'adds an info message' do
        stub_response = double('response', code: '200')
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(stub_response)

        check = build_check(url: 'http://example.com/health', expected_status: 200)
        result = check.run
        expect(result.errors).to be_empty
        expect(result.infos).to include(match(/responded with 200/))
      end
    end

    context 'when endpoint returns unexpected status' do
      it 'adds an error' do
        stub_response = double('response', code: '503')
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(stub_response)

        check = build_check(url: 'http://example.com/health', expected_status: 200)
        result = check.run
        expect(result.errors).to include(match(/returned 503, expected 200/))
      end
    end

    context 'when connection is refused' do
      it 'adds an error' do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Errno::ECONNREFUSED)

        check = build_check(url: 'http://localhost:9999/health')
        result = check.run
        expect(result.errors).to include(match(/connection refused/))
      end
    end

    context 'when request times out' do
      it 'adds an error' do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Net::OpenTimeout)

        check = build_check(url: 'http://example.com/health', timeout: 3)
        result = check.run
        expect(result.errors).to include(match(/timed out after 3s/))
      end
    end

    context 'when API_HEALTH_URL env var is set' do
      around do |example|
        ENV['API_HEALTH_URL'] = 'http://env-api.example.com/health'
        example.run
        ENV.delete('API_HEALTH_URL')
      end

      it 'uses the env var URL' do
        stub_response = double('response', code: '200')
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(stub_response)

        check = described_class.new
        result = check.run
        expect(result.infos).to include(match(/env-api\.example\.com/))
      end
    end
  end
end
