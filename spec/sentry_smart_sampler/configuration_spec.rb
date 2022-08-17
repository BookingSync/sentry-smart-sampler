# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentrySmartSampler::Configuration do
  describe "cache_storage" do
    subject(:cache_storage) { configuration.cache_storage }

    let(:configuration) { described_class.new }

    context "when set" do
      let(:cache_storage_for_config) { double }

      before do
        configuration.cache_storage = cache_storage_for_config
      end

      it { is_expected.to eq cache_storage_for_config }
    end

    context "when not set" do
      it { is_expected.to be_nil }
    end
  end

  describe "logger" do
    subject(:logger) { configuration.logger }

    let(:configuration) { described_class.new }

    context "when set" do
      let(:logger_for_config) { double }

      before do
        configuration.logger = logger_for_config
      end

      it { is_expected.to eq logger_for_config }
    end

    context "when not set" do
      it { is_expected.to be_nil }
    end
  end

  describe "default_sample_rate" do
    subject(:default_sample_rate) { configuration.default_sample_rate }

    let(:configuration) { described_class.new }

    context "when set" do
      let(:default_sample_rate_for_config) { 0.3 }

      before do
        configuration.default_sample_rate = default_sample_rate_for_config
      end

      it { is_expected.to eq default_sample_rate_for_config }
    end

    context "when not set" do
      it { is_expected.to eq 1 }
    end
  end

  describe "default_throttling_errors_number_threshold" do
    subject(:default_throttling_errors_number_threshold) { configuration.default_throttling_errors_number_threshold }

    let(:configuration) { described_class.new }

    context "when set" do
      let(:default_throttling_errors_number_threshold_for_config) { 100 }

      before do
        configuration.default_throttling_errors_number_threshold = default_throttling_errors_number_threshold_for_config
      end

      it { is_expected.to eq default_throttling_errors_number_threshold_for_config }
    end

    context "when not set" do
      it { is_expected.to be_nil }
    end
  end

  describe "default_throttling_time_unit" do
    subject(:default_throttling_time_unit) { configuration.default_throttling_time_unit }

    let(:configuration) { described_class.new }

    context "when set" do
      context "when it's :second" do
        let(:default_throttling_time_unit_for_config) { :second }

        before do
          configuration.default_throttling_time_unit = default_throttling_time_unit_for_config
        end

        it { is_expected.to eq default_throttling_time_unit_for_config }
      end

      context "when it's :minute" do
        let(:default_throttling_time_unit_for_config) { :minute }

        before do
          configuration.default_throttling_time_unit = default_throttling_time_unit_for_config
        end

        it { is_expected.to eq default_throttling_time_unit_for_config }
      end

      context "when it's :hour" do
        let(:default_throttling_time_unit_for_config) { :hour }

        before do
          configuration.default_throttling_time_unit = default_throttling_time_unit_for_config
        end

        it { is_expected.to eq default_throttling_time_unit_for_config }
      end

      context "when it's :day" do
        let(:default_throttling_time_unit_for_config) { :day }

        before do
          configuration.default_throttling_time_unit = default_throttling_time_unit_for_config
        end

        it { is_expected.to eq default_throttling_time_unit_for_config }
      end

      context "when it's something else" do
        subject(:set_default_throttling_time_unit) { configuration.default_throttling_time_unit = :something_else }

        it { is_expected_block.to raise_error ArgumentError, %r{Invalid time unit: :something_else} }
      end
    end

    context "when not set" do
      it { is_expected.to be_nil }
    end
  end

  describe "after_throttling_threshold_reached" do
    subject(:execute_callback) do
      configuration.after_throttling_threshold_reached.call(double, { exception: StandardError.new("message") })
    end

    let(:after_throttling_threshold_reached) { configuration.after_throttling_threshold_reached }
    let(:configuration) { described_class.new }
    let(:logger) do
      Class.new do
        attr_reader :message

        def info(message_to_log)
          @message = message_to_log
        end
      end.new
    end

    before do
      configuration.logger = logger
    end

    context "when set" do
      before do
        configuration.after_throttling_threshold_reached = lambda do |_event, hint|
          logger.info("Custom handler for error: #{hint[:exception].message}")
        end
      end

      it { is_expected_block.to change { logger.message }.to("Custom handler for error: message") }
    end

    context "when not set" do
      let(:expected_message) do
        "[SentrySmartSampler] Throttling threshold reached for StandardError: message"
      end

      it { is_expected_block.to change { logger.message }.to(expected_message) }
    end
  end

  describe "#sampling_rate_per_error_registry" do
    subject(:sampling_rate_per_error_registry) { configuration.sampling_rate_per_error_registry }

    let(:configuration) { described_class.new }

    it { is_expected.to be_a(SentrySmartSampler::SampleRatePerErrorRegistry) }
  end

  describe "#throttling_per_error_registry" do
    subject(:throttling_per_error_registry) { configuration.throttling_per_error_registry }

    let(:configuration) { described_class.new }

    it { is_expected.to be_a(SentrySmartSampler::ThrottlingPerErrorRegistry) }
  end
end
