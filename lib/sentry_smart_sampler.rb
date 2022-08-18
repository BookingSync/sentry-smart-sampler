# frozen_string_literal: true

require "sentry/smart/sampler/version"
require "active_support"
require "active_support/core_ext"
require "sentry_smart_sampler/configuration"
require "sentry_smart_sampler/rate_limit"
require "sentry_smart_sampler/sampler"
require "sentry_smart_sampler/sample_rate_per_error_registry"
require "sentry_smart_sampler/throttling_per_error_registry"
require "sentry_smart_sampler/throttling_threshold_reached_definition"

class SentrySmartSampler
  def self.configuration
    @configuration ||= SentrySmartSampler::Configuration.new
  end

  def self.configure
    yield configuration
  end

  def self.sample_rate_registration_for(error)
    configuration.sampling_rate_per_error_registry.sample_rate_registration_for(error)
  end

  def self.throttling_registration_for(error)
    configuration.throttling_per_error_registry.throttling_registration_for(error)
  end

  def self.call(event, hint)
    SentrySmartSampler::Sampler.new(self).call(event, hint)
  end

  def self.reset!
    @configuration = nil
  end
end
