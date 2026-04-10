require "spec_helper"
require "rails_deploy_check/checks/healthcheck_check"

RSpec.describe RailsDeployCheck::Checks::HealthcheckCheck do
  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(overrides = {})
    described_class.new({ app_root: @tmpdir }.merge(overrides))
  end

  around do |example|
    with_tmp_rails_app { |dir| @tmpdir = dir; example.run }
  end

  describe "#run" do
    context "when routes.rb is missing" do
      it "adds a warning" do
        result = build_check.run
        expect(result.warnings.first).to match(/routes.rb not found/)
      end
    end

    context "when routes.rb contains a healthcheck path" do
      before do
        create_file(
          File.join(@tmpdir, "config", "routes.rb"),
          "Rails.application.routes.draw { get 'healthz', to: 'health#show' }"
        )
      end

      it "reports an info message" do
        result = build_check.run
        expect(result.infos.first).to match(%r{/healthz})
        expect(result.warnings).to be_empty
      end
    end

    context "when routes.rb has no healthcheck path" do
      before do
        create_file(
          File.join(@tmpdir, "config", "routes.rb"),
          "Rails.application.routes.draw { root 'pages#home' }"
        )
      end

      it "adds a warning suggesting paths" do
        result = build_check.run
        expect(result.warnings.first).to match(/No healthcheck route found/)
      end
    end

    context "when a host is provided" do
      before do
        create_file(
          File.join(@tmpdir, "config", "routes.rb"),
          "Rails.application.routes.draw { get 'up', to: 'rails/health#show' }"
        )
      end

      it "adds info when endpoint responds successfully" do
        stub_response = instance_double(Net::HTTPSuccess, code: "200")
        allow(Net::HTTP).to receive(:start).and_return(stub_response)

        result = build_check(host: "localhost", port: 3000).run
        expect(result.infos.any? { |i| i.include?("200") }).to be true
      end

      it "adds a warning when connection is refused" do
        allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED, "refused")

        result = build_check(host: "localhost", port: 3000).run
        expect(result.warnings.any? { |w| w.include?("Could not reach") }).to be true
      end

      it "adds an error on 5xx when require_ok is true" do
        stub_response = instance_double(Net::HTTPServerError, code: "503")
        allow(Net::HTTP).to receive(:start).and_return(stub_response)

        result = build_check(host: "localhost", require_ok: true).run
        expect(result.errors.any? { |e| e.include?("503") }).to be true
      end
    end
  end
end
