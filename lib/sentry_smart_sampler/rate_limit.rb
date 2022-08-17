# frozen_string_literal: true

class SentrySmartSampler::RateLimit
  KEY_PREFIX = "sentry_smart_sampler"
  private_constant :KEY_PREFIX

  attr_reader :key, :threshold, :interval, :increment, :cache
  private     :key, :threshold, :interval, :increment, :cache

  def initialize(key:, threshold:, interval:, increment: 1, cache: SentrySmartSampler.configuration.cache_storage)
    @key = key
    @threshold = threshold
    @interval = interval
    @increment = increment
    @cache = cache
  end

  def throttled?
    count >= threshold
  end

  def count
    cache.read(storage_key, raw: true).to_i
  end

  def remaining
    threshold - count
  end

  def clear!
    cache.delete(storage_key)
  end

  def increase
    cache.increment(storage_key, increment) || increment
  end

  def storage_key
    "#{KEY_PREFIX}/#{normalized_key}"
  end

  # let's say that the interval is 1.hour
  # the current time is 15:05
  # window is going to keep the same value until another interval time starts
  # a new window is going to be start at 16:00
  def window
    Time.current.to_i / interval
  end

  private

  def normalized_key
    Digest::MD5.hexdigest([key, window].flatten.join("/"))
  end
end
