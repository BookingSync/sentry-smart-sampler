# frozen_string_literal: true

class SentrySmartSampler
  class ThrottlingPerErrorRegistry
    attr_reader :default_throttling_errors_number_threshold, :default_throttling_time_unit, :registry
    private     :default_throttling_errors_number_threshold, :default_throttling_time_unit, :registry

    def initialize(default_throttling_errors_number_threshold, default_throttling_time_unit)
      @default_throttling_errors_number_threshold = default_throttling_errors_number_threshold
      @default_throttling_time_unit = default_throttling_time_unit
      @registry = []
    end

    def declare(throttable, time_unit:, threshold:)
      registry << Registration.new(throttable: throttable, time_unit: time_unit, threshold: threshold)
    end

    def throttling_registration_for(error)
      registry.find(-> { default_registration }) { |registration| registration.matches?(error) }
    end

    private

    def default_registration
      Registration.new(throttable: nil, time_unit: default_throttling_time_unit,
        threshold: default_throttling_errors_number_threshold)
    end

    class Registration
      attr_reader :throttable, :threshold, :time_unit

      def initialize(throttable:, threshold:, time_unit:)
        @throttable = throttable
        @threshold = threshold
        @time_unit = time_unit
      end

      def matches?(matchable)
        matchable.is_a?(throttable)
      end
    end
  end
end
