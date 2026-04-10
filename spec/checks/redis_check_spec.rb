# frozen_string_literal: true

require "spec_helper"
require "rails_deploy_check/checks/redis_check"

RSpec.describe RailsDeployCheck::Checks::RedisCheck do
  def build_check(config = {})
    described_class.new(config)
  end

  describe "#run" do
    context "when Redis gem is not available" do
      before do
        allow_any_instance_of(described_class).to receive(:require).with("redis").and_raise(LoadError)
      end

      it "adds a warning when Redis is not required" do
        result = build_check(required: false).run
        expect(result.warnings).to include(a_string_matching(/Redis gem not found/))
      end

      it "adds an error when Redis is required" do
        result = build_check(required: true).run
        expect(result.errors).to include(a_string_matching(/Redis gem is not available/))
      end
    end

    context "when Redis gem is available" do
      let(:redis_double) { instance_double("Redis", ping: "PONG") }

      before do
        stub_const("Redis", Class.new)
        stub_const("Redis::CannotConnectError", Class.new(StandardError))
        stub_const("Redis::ConnectionError", Class.new(StandardError))
        allow(Redis).to receive(:new).and_return(redis_double)
      end

      it "reports successful connection" do
        result = build_check(url: "redis://localhost:6379").run
        expect(result.infos).to include(a_string_matching(/Redis connection successful/))
      end

      it "adds info that the gem is available" do
        result = build_check(url: "redis://localhost:6379").run
        expect(result.infos).to include(a_string_matching(/Redis gem is available/))
      end

      context "when connection fails" do
        before do
          allow(redis_double).to receive(:ping).and_raise(Redis::CannotConnectError, "refused")
        end

        it "adds a warning when not required" do
          result = build_check(url: "redis://localhost:6379", required: false).run
          expect(result.warnings).to include(a_string_matching(/Cannot connect to Redis/))
        end

        it "adds an error when required" do
          result = build_check(url: "redis://localhost:6379", required: true).run
          expect(result.errors).to include(a_string_matching(/Cannot connect to Redis/))
        end
      end
    end

    context "with invalid Redis URL" do
      it "reports an error for unsupported scheme" do
        result = build_check(url: "http://localhost:6379").run
        expect(result.errors).to include(a_string_matching(/Invalid Redis URL scheme/))
      end

      it "reports an error for malformed URL" do
        result = build_check(url: "not a url !!!").run
        expect(result.errors).to include(a_string_matching(/Malformed Redis URL/))
      end
    end

    context "URL defaults" do
      it "uses REDIS_URL env variable when set" do
        allow(ENV).to receive(:[]).with("REDIS_URL").and_return("redis://myhost:6380")
        check = described_class.new
        expect(check.instance_variable_get(:@url)).to eq("redis://myhost:6380")
      end

      it "falls back to default URL" do
        allow(ENV).to receive(:[]).with("REDIS_URL").and_return(nil)
        check = described_class.new
        expect(check.instance_variable_get(:@url)).to eq("redis://localhost:6379")
      end
    end
  end
end
