require "spec_helper"

describe MultiJson::OptionsCache do
  before { described_class.reset }

  it "doesn't leak memory" do
    max = described_class::Store.const_get(:MAX_CACHE_SIZE)
    max.succ.times do |i|
      described_class.dump.fetch(key: i) do
        {foo: i}
      end

      described_class.load.fetch(key: i) do
        {foo: i}
      end
    end

    expect(described_class.dump.instance_variable_get(:@cache).length).to eq(1)
    expect(described_class.load.instance_variable_get(:@cache).length).to eq(1)
  end

  it "stores value in current cache after reset" do
    described_class.load.fetch(:foo) do
      described_class.reset
      :bar
    end

    expect(described_class.load.fetch(:foo) { :baz }).to eq(:baz)
  end
end
