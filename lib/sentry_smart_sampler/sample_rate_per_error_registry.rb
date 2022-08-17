# frozen_string_literal: true

class SentrySmartSampler
  class SampleRatePerErrorRegistry
    attr_reader :default_sample_rate, :registry
    private     :default_sample_rate, :registry

    def initialize(default_sample_rate)
      @default_sample_rate = default_sample_rate
      @registry = []
    end

    def declare(samplable, sample_rate:)
      registry << Registration.new(samplable: samplable, sample_rate: sample_rate)
    end

    def sample_rate_registration_for(error)
      registry.find(-> { default_registration }) { |registration| registration.matches?(error) }
    end

    private

    def default_registration
      Registration.new(samplable: nil, sample_rate: default_sample_rate)
    end

    class Registration
      attr_reader :samplable, :sample_rate

      def initialize(samplable:, sample_rate:)
        @samplable = samplable
        @sample_rate = sample_rate
      end

      def matches?(matchable)
        matchable.is_a?(samplable)
      end
    end
  end
end
