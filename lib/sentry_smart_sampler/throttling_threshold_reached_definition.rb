# frozen_string_literal: true

class SentrySmartSampler
  class ThrottlingThresholdReachedDefinition
    def reached?(rate_limit, throttling_registration, _error)
      rate_limit.throttled? && rate_limit.count == throttling_registration.threshold
    end
  end
end
