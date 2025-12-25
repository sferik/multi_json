require_relative "../../test_helper"

class OptionsCacheStoreAndEvictionTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_store_returns_value_from_assignment
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:sv_test) { "stored_value" }

    assert_equal "stored_value", result
  end

  def test_store_stores_passed_value
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:direct_store) { "direct_value" }
    cache = store.instance_variable_get(:@cache)

    assert_equal "direct_value", cache[:direct_store]
  end

  def test_store_checks_key_exists_before_storing
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:preexist] = "old"

    result = store.send(:store, :preexist, "new")

    assert_equal "old", result
    assert_equal "old", cache[:preexist]
  end

  def test_cache_shift_at_max_boundary_size_maintained
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE
    max.times { |i| store.fetch(:"k#{i}") { i } }
    cache = store.instance_variable_get(:@cache)

    assert_equal max, cache.size

    store.fetch(:extra) { "extra" }

    assert_equal max, cache.size
  end

  def test_cache_shift_at_max_boundary_evicts_oldest
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE
    max.times { |i| store.fetch(:"k#{i}") { i } }
    cache = store.instance_variable_get(:@cache)

    assert cache.key?(:k0)

    store.fetch(:extra) { "extra" }

    refute cache.key?(:k0)
  end

  def test_cache_no_shift_below_max
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE
    (max - 1).times { |i| store.fetch(:"below#{i}") { i } }

    cache = store.instance_variable_get(:@cache)
    store.fetch(:at_max) { "at_max" }

    assert_equal max, cache.size
    assert cache.key?(:below0)
  end

  def test_store_shifts_when_size_greater_than_max
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE

    # Directly set cache to above max size (simulates race condition)
    (max + 5).times { |i| cache[:"over#{i}"] = i }

    assert_operator cache.size, :>, max
    first_key = :over0

    assert cache.key?(first_key)

    # Now store should still shift because size >= MAX
    store.send(:store, :new_key, "new_value")

    # First key should have been removed by shift
    refute cache.key?(first_key), "Cache should shift when size > MAX_CACHE_SIZE"
  end

  def test_store_with_gte_operator_shifts_above_max
    # Explicitly test that cache shifts when size is ABOVE max, not just equal
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE

    # Fill to exactly max + 1
    (max + 1).times { |i| cache[:"fill#{i}"] = i }
    initial_size = cache.size

    assert_operator initial_size, :>, max
    first_key = :fill0

    assert cache.key?(first_key)

    # store should shift because size > max (>= max is true)
    store.send(:store, :after_overflow, "value")

    # First key should have been removed
    refute cache.key?(first_key), "Cache should have shifted when size > MAX"
  end
end
