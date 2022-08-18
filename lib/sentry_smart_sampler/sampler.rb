# frozen_string_literal: true

class SentrySmartSampler
  class Sampler
    attr_reader :registry, :random_generator, :cache_storage, :after_throttling_threshold_reached,
      :throttling_threshold_reached_definition
    private     :registry, :random_generator, :cache_storage, :after_throttling_threshold_reached,
      :throttling_threshold_reached_definition

    def initialize(registry, random_generator: Random, configuration: SentrySmartSampler.configuration)
      @registry = registry
      @random_generator = random_generator
      @cache_storage = configuration.cache_storage
      @after_throttling_threshold_reached = configuration.after_throttling_threshold_reached
      @throttling_threshold_reached_definition = configuration.throttling_threshold_reached_definition
    end

    def call(event, hint)
      error = hint[:exception]
      throttling_registration = registry.throttling_registration_for(error)

      if apply_throttling?(throttling_registration)
        rate_limit = initialize_rate_limit(throttling_registration, error)
        already_throttled = rate_limit.throttled?
        rate_limit.increase
        after_throttling_threshold_reached.call(event, hint) if throttling_threshold_reached_definition.reached?(
          rate_limit, throttling_registration, error
        )
        return if already_throttled
      end

      sample(event, error)
    end

    private

    def apply_throttling?(throttling_registration)
      throttling_registration.threshold && throttling_registration.time_unit && cache_storage
    end

    def initialize_rate_limit(throttling_registration, error)
      SentrySmartSampler::RateLimit.new(key: throttling_registration.throttable || error.class,
        threshold: throttling_registration.threshold,
        interval: 1.public_send(throttling_registration.time_unit),
        cache: cache_storage)
    end

    def threshold_reached?(rate_limit, throttling_registration, error); end

    def sample(event, error)
      event if random_generator.rand <= registry.sample_rate_registration_for(error).sample_rate
    end
  end
end
