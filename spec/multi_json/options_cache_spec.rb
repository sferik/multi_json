require "spec_helper"

describe MultiJson::OptionsCache do
  before do
    described_class.reset
    max = described_class::MAX_CACHE_SIZE

    (max + 1).times do |i|
      described_class.dump.fetch(key: i) { {foo: i} }
      described_class.load.fetch(key: i) { {foo: i} }
    end
  end

  it "doesn't leak memory" do
    caches = [described_class.dump, described_class.load].map { |cache| cache.instance_variable_get(:@cache).length }

    expect(caches).to all(eq(1))
  end

  it "stores value in current cache after reset" do
    described_class.load.fetch(:foo) do
      described_class.reset
      :bar
    end

    expect(described_class.load.fetch(:foo, :baz)).to eq(:baz)
  end

  it "executes block only once per key in concurrent access" do
    described_class.reset
    counter = 0
    Array.new(5) { Thread.new { described_class.dump.fetch(:foo) { counter += 1 } } }.each(&:join)
    expect(counter).to eq(1)
  end
end
