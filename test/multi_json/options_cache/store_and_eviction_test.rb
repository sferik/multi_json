require_relative "../../test_helper"

class OptionsCacheStoreAndEvictionTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_store_returns_value_from_assignment
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:sv_test) { "stored_value" }

    assert_equal "stored_value", result
  end

  def test_store_persists_value_across_calls
    store = MultiJson::OptionsCache::Store.new

    store.fetch(:direct_store) { "direct_value" }

    assert_equal "direct_value", store.fetch(:direct_store) { "should_not_use_this" }
  end

  def test_store_returns_existing_value_when_key_present
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:preexist) { "old" }

    assert_equal "old", store.fetch(:preexist) { "new" }
  end

  def test_cache_size_bounded_at_max
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE

    (max + 1).times { |i| store.fetch(:"k#{i}") { i } }

    cache = store.instance_variable_get(:@cache)

    assert_operator cache.size, :<=, max
  end

  def test_cache_evicts_some_entry_when_at_max
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE
    max.times { |i| store.fetch(:"k#{i}") { i } }

    cache = store.instance_variable_get(:@cache)

    assert_equal max, cache.size

    store.fetch(:extra) { "extra" }

    assert_operator cache.size, :<=, max
    assert cache.key?(:extra)
  end

  def test_cache_no_eviction_below_max
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE
    (max - 1).times { |i| store.fetch(:"below#{i}") { i } }

    cache = store.instance_variable_get(:@cache)
    store.fetch(:at_max) { "at_max" }

    assert_equal max, cache.size
    assert cache.key?(:below0)
  end

  def test_cache_evicts_when_size_above_max_not_just_equal
    # Pre-populate the cache above MAX_CACHE_SIZE by writing directly to
    # @cache, bypassing the fetch eviction. This distinguishes a correct
    # ``size >= MAX`` check from the equivalent-looking ``size == MAX``
    # mutation: above-max, ``>=`` evicts on the next fetch but ``==``
    # does not. Assert the size dropped after fetch (one entry shifted).
    skip "Concurrent::Map on JRuby does not support direct []=" if RUBY_ENGINE == "jruby"

    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE
    cache = store.instance_variable_get(:@cache)
    (max + 5).times { |i| cache[:"pre#{i}"] = i }
    size_before = cache.size

    assert_operator size_before, :>, max

    store.fetch(:after_overflow) { "after_overflow" }

    # ``>=`` shifts one existing entry then adds the new one: size stays flat.
    # ``==`` does nothing (size is not exactly MAX), so the new key would add
    # one: size would grow by 1.
    assert_equal size_before, cache.size
    assert cache.key?(:after_overflow)
  end
end
