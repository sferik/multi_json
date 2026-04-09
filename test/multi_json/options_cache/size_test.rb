# frozen_string_literal: true

require_relative "../../test_helper"

# Tests for cache size management. Concurrent::Map is unordered so we
# verify only that memory is bounded and that the most recent insert
# survives. Strict LRU semantics are not required.
class OptionsCacheSizeTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
  end

  def test_store_evicts_when_at_max_size
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache.max_cache_size
    max.times { |i| store.fetch(:"key#{i}") { "value#{i}" } }

    store.fetch(:overflow_key) { "overflow_value" }

    cache = store.instance_variable_get(:@cache)

    assert_operator cache.size, :<=, max
    assert_equal "overflow_value", cache[:overflow_key]
  end

  def test_store_size_stays_bounded
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache.max_cache_size

    (max * 2).times { |i| store.fetch(:"key#{i}") { "value#{i}" } }

    cache = store.instance_variable_get(:@cache)

    assert_operator cache.size, :<=, max
  end

  def test_store_no_eviction_below_max
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache.max_cache_size
    (max - 1).times { |i| store.fetch(:"key#{i}") { "value#{i}" } }
    store.fetch(:new_key) { "new_value" }

    cache = store.instance_variable_get(:@cache)

    assert_equal max, cache.size
    assert cache.key?(:key0)
  end
end
