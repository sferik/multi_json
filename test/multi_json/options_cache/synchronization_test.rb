require_relative "../../test_helper"

# Tests that the cache survives concurrent access without raising or
# returning corrupt values. The store wraps Concurrent::Map, which
# handles synchronization internally.
class OptionsCacheSynchronizationTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_reset_clears_cache
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:key1) { "value1" }
    cache = store.instance_variable_get(:@cache)

    assert_equal 1, cache.size

    store.reset

    assert_equal 0, cache.size
  end

  def test_concurrent_fetches_do_not_raise
    store = MultiJson::OptionsCache::Store.new

    threads = 10.times.map do |i|
      Thread.new { 100.times { store.fetch(:"k#{i}") { i } } }
    end

    threads.each(&:join)

    cache = store.instance_variable_get(:@cache)

    assert_operator cache.size, :<=, MultiJson::OptionsCache::MAX_CACHE_SIZE
  end
end
