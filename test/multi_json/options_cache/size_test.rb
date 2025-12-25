require_relative "../../test_helper"

# Tests for cache size management
class OptionsCacheSizeTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
  end

  def test_store_shifts_when_at_max_size
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE

    # Fill to max
    max.times { |i| store.fetch(:"key#{i}") { "value#{i}" } }

    # Add one more
    store.fetch(:overflow_key) { "overflow_value" }

    cache = store.instance_variable_get(:@cache)

    assert_equal max, cache.size
    assert_equal "overflow_value", cache[:overflow_key]
  end

  def test_store_shift_removes_oldest_entry
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE

    # Fill to max
    max.times { |i| store.fetch(:"key#{i}") { "value#{i}" } }

    cache = store.instance_variable_get(:@cache)

    # First key should still exist
    assert cache.key?(:key0)

    # Add one more to trigger shift
    store.fetch(:new_key) { "new_value" }

    # First key should be removed
    refute cache.key?(:key0)
  end

  def test_store_checks_cache_size
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE

    # Fill exactly to max
    max.times { |i| store.fetch(:"key#{i}") { "value#{i}" } }

    cache = store.instance_variable_get(:@cache)

    assert_equal max, cache.size
  end

  def test_store_shifts_first_key_when_exceeding_max
    # Tests >= boundary: shift happens when adding beyond max
    store, cache = create_store_at_max_size
    store.fetch(:overflow) { "value" }

    refute cache.key?(:key0), "First key should be removed after exceeding max"
  end

  def test_store_maintains_max_size_after_overflow
    store, cache = create_store_at_max_size
    store.fetch(:overflow) { "value" }

    assert_equal MultiJson::OptionsCache::MAX_CACHE_SIZE, cache.size
  end

  def test_store_keeps_first_key_at_exactly_max
    # Fill to max-1, then add one more to reach exactly max (no shift)
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE
    (max - 1).times { |i| store.fetch(:"key#{i}") { "value#{i}" } }
    store.fetch(:new_key) { "new_value" }

    assert store.instance_variable_get(:@cache).key?(:key0)
  end

  private

  def create_store_at_max_size
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE
    max.times { |i| store.fetch(:"key#{i}") { "value#{i}" } }
    [store, store.instance_variable_get(:@cache)]
  end
end
