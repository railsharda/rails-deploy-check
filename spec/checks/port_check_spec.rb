require "spec_helper"
require "rails_deploy_check/checks/port_check"

RSpec.describe RailsDeployCheck::Checks::PortCheck do
  def build_check(options = {})
    described_class.new(options)
  end

  describe "#run" do
    context "when no ports are configured" do
      it "returns an info message" do
        check = build_check(ports: [])
        result = check.run
        expect(result.infos).to include(match(/No ports configured/))
        expect(result).to be_passed
      end
    end

    context "with an invalid port number" do
      it "adds an error for port 0" do
        check = build_check(ports: [0])
        result = check.run
        expect(result.errors).to include(match(/Invalid port number: 0/))
      end

      it "adds an error for port 99999" do
        check = build_check(ports: [99_999])
        result = check.run
        expect(result.errors).to include(match(/Invalid port number: 99999/))
      end
    end

    context "when a port is open" do
      it "adds an info message" do
        check = build_check(ports: [80], host: "127.0.0.1")
        allow_any_instance_of(TCPSocket).to receive(:close)
        allow(TCPSocket).to receive(:new).with("127.0.0.1", 80).and_return(double(close: nil))

        result = check.run
        expect(result.infos).to include(match(/Port 80 is open/))
      end
    end

    context "when a port is closed" do
      it "adds a warning message" do
        check = build_check(ports: [9999], host: "127.0.0.1", timeout: 1)
        allow(TCPSocket).to receive(:new).and_raise(Errno::ECONNREFUSED)

        result = check.run
        expect(result.warnings).to include(match(/Port 9999 is not reachable/))
        expect(result).to be_passed
      end
    end

    context "with multiple ports" do
      it "checks each port independently" do
        check = build_check(ports: [80, 443], host: "127.0.0.1", timeout: 1)
        allow(TCPSocket).to receive(:new).with("127.0.0.1", 80).and_return(double(close: nil))
        allow(TCPSocket).to receive(:new).with("127.0.0.1", 443).and_raise(Errno::ECONNREFUSED)

        result = check.run
        expect(result.infos).to include(match(/Port 80 is open/))
        expect(result.warnings).to include(match(/Port 443 is not reachable/))
      end
    end
  end
end
