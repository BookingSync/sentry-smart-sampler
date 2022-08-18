# frozen_string_literal: true

require "spec_helper"

RSpec.describe SentrySmartSampler::ThrottlingThresholdReachedDefinition do
  describe "#reached?" do
    subject(:reached?) { definition.reached?(rate_limit, throttling_registration, error) }

    let(:definition) { described_class.new }
    let(:rate_limit) { instance_double(SentrySmartSampler::RateLimit, throttled?: throttled, count: count) }
    let(:throttling_registration) do
      SentrySmartSampler::ThrottlingPerErrorRegistry::Registration.new(throttable: RuntimeError, time_unit: :minute,
        threshold: threshold)
    end
    let(:threshold) { 50 }
    let(:error) { RuntimeError.new }

    context "when throttled" do
      let(:throttled) { true }

      context "when count is equal to threshold" do
        let(:count) { threshold }

        it { is_expected.to be true }
      end

      context "when count is lower than threshold" do
        let(:count) { threshold - 1 }

        it { is_expected.to be false }
      end

      context "when count is higher than threshold" do
        let(:count) { threshold + 1 }

        it { is_expected.to be false }
      end
    end

    context "when not throttled" do
      let(:throttled) { false }

      context "when count is equal to threshold" do
        let(:count) { threshold }

        it { is_expected.to be false }
      end

      context "when count is lower than threshold" do
        let(:count) { threshold - 1 }

        it { is_expected.to be false }
      end

      context "when count is higher than threshold" do
        let(:count) { threshold + 1 }

        it { is_expected.to be false }
      end
    end
  end
end
