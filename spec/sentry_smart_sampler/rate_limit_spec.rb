# frozen_string_literal: true

require "spec_helper"
require "active_support/cache/redis_cache_store"

RSpec.describe SentrySmartSampler::RateLimit, :freeze_time do
  let(:rate_limit) do
    described_class.new(key: key, threshold: threshold, interval: interval, increment: increment, cache: cache_store)
  end
  let(:key) { "key" }
  let(:threshold) { 10 }
  let(:interval) { 1.hour }
  let(:increment) { 1 }
  let(:cache_store) { ActiveSupport::Cache::RedisCacheStore.new(url: redis_url) }
  let(:redis_url) { ENV.fetch("REDIS_URL", "redis://localhost:6379") }
  let(:repeat_occurrence) do
    ->(count) { count.times { rate_limit.increase } }
  end

  before do
    rate_limit.clear!
  end

  describe "#throttled?" do
    subject(:throttled?) { rate_limit.throttled? }

    context "when below threshold" do
      before { repeat_occurrence.call(threshold - 1) }

      it "allows further occurrences" do
        expect(throttled?).to be false
      end
    end

    context "when at threshold" do
      before { repeat_occurrence.call(threshold) }

      it "doesn't allow further occurrences" do
        expect(throttled?).to be true
      end
    end

    context "when cache is down" do
      let(:redis_url) { "redis://localhost:123/4" }

      before { repeat_occurrence.call(threshold) }

      it "does not throttle" do
        expect(throttled?).to be false
      end
    end
  end

  describe "#count/#increase" do
    subject(:count) { rate_limit.count }

    context "when there is nothing in the storage" do
      it { is_expected.to eq 0 }
    end

    context "when there is something in the storage" do
      before do
        2.times { rate_limit.increase }
      end

      it { is_expected.to eq 2 }
    end
  end

  describe "#remaining" do
    subject(:remaining) { rate_limit.remaining }

    context "when below threshold" do
      before { repeat_occurrence.call(threshold - 1) }

      it "shows remaining occurrences" do
        expect(remaining).to eq(1)
      end
    end

    context "when at threshold" do
      before { repeat_occurrence.call(threshold) }

      it "doesn't allow further occurrences" do
        expect(remaining).to eq(0)
      end
    end
  end

  describe "#clear!" do
    subject(:clear!) { rate_limit.clear! }

    before do
      repeat_occurrence.call(5)

      allow(cache_store).to receive(:delete).and_call_original
    end

    it "clears storage" do
      expect do
        clear!
      end.to change { rate_limit.count }.from(5).to(0)

      expect(cache_store).to have_received(:delete).with(%r{sentry_smart_sampler})
    end
  end

  describe "#storage_key" do
    subject(:storage_key) { rate_limit.storage_key }

    let(:normalized_key) { Digest::MD5.hexdigest("#{key}/#{window}") }
    let(:window) { Time.current.to_i / interval }

    it { is_expected.to eq("sentry_smart_sampler/#{normalized_key}") }
  end

  describe "#window", freeze_time: "2022-08-17T15:05:00Z" do
    subject(:window) { rate_limit.window }

    describe "for current time", freeze_time: "2022-08-17T15:05:00Z" do
      it { is_expected.to eq(461_319) }
    end

    describe "30 minutes later", freeze_time: "2022-08-17T15:35:00Z" do
      it { is_expected.to eq(461_319) }
    end

    describe "54 minutes later", freeze_time: "2022-08-17T15:59:00Z" do
      it { is_expected.to eq(461_319) }
    end

    describe "55 minutes later", freeze_time: "2022-08-17T16:00:00Z" do
      it { is_expected.to eq(461_320) }
    end
  end
end
