require "spec_helper"

RSpec.describe RailsDeployCheck::Checks::CacheCheck do
  def create_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_check(app_path, rails_env: "production")
    described_class.new(app_path: app_path, rails_env: rails_env)
  end

  around do |example|
    with_tmp_rails_app { |path| @app_path = path; example.run }
  end

  let(:env_config_path) { File.join(@app_path, "config", "environments", "production.rb") }

  describe "#run" do
    context "when environment config is missing" do
      it "adds a warning" do
        result = build_check(@app_path).run
        expect(result.warnings).to include(match(/Environment config not found/))
      end
    end

    context "when cache_store is not configured" do
      before { create_file(env_config_path, "Rails.application.configure do\nend\n") }

      it "adds a warning about missing cache_store" do
        result = build_check(@app_path).run
        expect(result.warnings).to include(match(/No explicit cache_store configuration/))
      end
    end

    context "when a known cache store is configured" do
      before do
        create_file(env_config_path, "config.cache_store = :memory_store\n")
      end

      it "passes with info messages" do
        result = build_check(@app_path).run
        expect(result.errors).to be_empty
        expect(result.info).to include(match(/memory_store.*recognised/))
      end
    end

    context "when an unknown cache store is configured" do
      before do
        create_file(env_config_path, "config.cache_store = :custom_store\n")
      end

      it "adds a warning about unrecognised store" do
        result = build_check(@app_path).run
        expect(result.warnings).to include(match(/not a standard Rails cache backend/))
      end
    end

    context "when mem_cache_store is configured" do
      before do
        create_file(env_config_path, "config.cache_store = :mem_cache_store\n")
      end

      context "without MEMCACHE_SERVERS set" do
        it "warns about missing env variable" do
          ClimateControl.modify("MEMCACHE_SERVERS" => nil, "MEMCACHIER_SERVERS" => nil) do
            result = build_check(@app_path).run
            expect(result.warnings).to include(match(/MEMCACHE_SERVERS/))
          end
        end
      end

      context "with MEMCACHE_SERVERS set" do
        it "adds an info message" do
          ClimateControl.modify("MEMCACHE_SERVERS" => "localhost:11211") do
            result = build_check(@app_path).run
            expect(result.info).to include(match(/Memcache server environment variable is set/))
          end
        end
      end
    end

    context "when redis_cache_store is configured" do
      before do
        create_file(env_config_path, "config.cache_store = :redis_cache_store\n")
      end

      context "without REDIS_URL set" do
        it "warns about missing Redis URL" do
          ClimateControl.modify("REDIS_URL" => nil, "REDIS_CACHE_URL" => nil) do
            result = build_check(@app_path).run
            expect(result.warnings).to include(match(/REDIS_URL/))
          end
        end
      end

      context "with REDIS_URL set" do
        it "adds an info message" do
          ClimateControl.modify("REDIS_URL" => "redis://localhost:6379/1") do
            result = build_check(@app_path).run
            expect(result.info).to include(match(/Redis URL environment variable is set/))
          end
        end
      end
    end
  end
end
