# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentrySmartSampler::Sampler do
  describe "#call" do
    subject(:call) { sampler.call(event, hint) }

    let(:sampler) { described_class.new(registry) }
    let(:registry) { SentrySmartSampler }
    let(:event) { double }
    let(:hint) { { exception: error } }
    let(:error) { RuntimeError.new("message") }

    describe "sampling" do
      before do
        registry.configure do |config|
          config.default_sample_rate = 1

          config.declare_sampling_rate_per_error do
            declare RuntimeError, sample_rate: 0.1
          end
        end
      end

      context "when the error is allowed based on the sampling rate" do
        before do
          allow(Random).to receive(:rand).and_return(0.05)
        end

        it { is_expected.to eq event }
      end

      context "when the error is sampled out" do
        before do
          allow(Random).to receive(:rand).and_return(0.11)
        end

        it { is_expected.to be_nil }
      end
    end

    context "when the throttling should be applied", :freeze_time do
      before do
        rate_limit.clear!

        registry.configure do |config|
          config.cache_storage = cache_storage
          config.logger = logger
          config.default_sample_rate = 1
          config.default_throttling_errors_number_threshold = default_throttling_errors_number_threshold
          config.default_throttling_time_unit = default_throttling_time_unit
        end
      end

      let(:cache_storage) { ActiveSupport::Cache::RedisCacheStore.new(url: redis_url) }
      let(:redis_url) { ENV.fetch("REDIS_URL", "redis://localhost:6379") }
      let(:default_throttling_errors_number_threshold) { 10 }
      let(:default_throttling_time_unit) { :minute }
      let(:rate_limit) do
        SentrySmartSampler::RateLimit.new(key: RuntimeError, threshold: default_throttling_errors_number_threshold,
          interval: 1.minute, cache: cache_storage)
      end
      let(:logger) do
        Class.new do
          attr_reader :message

          def info(message)
            @message = message
          end
        end.new
      end

      context "when caling :throttling_threshold_reached_definition" do
        let(:throttling_threshold_reached_definition) do
          SentrySmartSampler.configuration.throttling_threshold_reached_definition
        end

        before do
          allow(SentrySmartSampler.configuration).to receive(:throttling_threshold_reached_definition)
            .and_return(throttling_threshold_reached_definition)
          allow(throttling_threshold_reached_definition).to receive(:reached?).and_call_original
        end

        it "calls the #reached? wit the right arguments" do
          call

          expect(throttling_threshold_reached_definition).to have_received(:reached?).with(
            an_instance_of(SentrySmartSampler::RateLimit),
            an_instance_of(SentrySmartSampler::ThrottlingPerErrorRegistry::Registration),
            error
          )
        end
      end

      context "when throttled" do
        before do
          default_throttling_errors_number_threshold.times { rate_limit.increase }
        end

        it { is_expected.to be_nil }
        it { is_expected_block.to change { rate_limit.count }.by(1) }
      end

      context "when not throttled" do
        context "when still not throttled after the increase" do
          before do
            (default_throttling_errors_number_threshold - 2).times { rate_limit.increase  }
          end

          it { is_expected_block.to change { rate_limit.count }.from(8).to(9) }
          it { is_expected.to eq event }
          it { is_expected_block.not_to change { logger.message } }
        end

        context "when throttled after the increase" do
          before do
            (default_throttling_errors_number_threshold - 1).times { rate_limit.increase  }
          end

          let(:expected_logger_message) do
            "[SentrySmartSampler] Throttling threshold reached for RuntimeError: message"
          end

          it { is_expected_block.to change { rate_limit.count }.from(9).to(10) }
          it { is_expected.to eq event }
          it { is_expected_block.to change { logger.message }.from(nil).to(expected_logger_message) }
        end
      end
    end
  end
end
