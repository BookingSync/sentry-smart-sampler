# frozen_string_literal: true

RSpec.describe Sentry::Smart::Sampler do
  it "has a version number" do
    expect(Sentry::Smart::Sampler::VERSION).not_to be_nil
  end
end
