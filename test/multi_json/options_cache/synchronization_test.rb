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

  def test_reset_holds_mutex_during_clear
    # Concurrent::Map (JRuby) handles synchronization internally; only
    # the MutexStore variant takes the mutex explicitly, and only on
    # that path is there anything to observe.
    skip "JRuby store uses Concurrent::Map" if RUBY_ENGINE == "jruby"

    store = MultiJson::OptionsCache::Store.new
    mutex = store.instance_variable_get(:@mutex)
    calls = stub_mutex_synchronize(mutex)

    store.reset

    assert_equal %i[synchronize_start synchronize_end], calls
  end

  def test_concurrent_fetches_do_not_raise
    store = MultiJson::OptionsCache::Store.new

    threads = 10.times.map do |i|
      Thread.new { 100.times { store.fetch(:"k#{i}") { i } } }
    end

    threads.each(&:join)

    cache = store.instance_variable_get(:@cache)

    assert_operator cache.size, :<=, MultiJson::OptionsCache.max_cache_size
  end

  private

  def stub_mutex_synchronize(mutex)
    calls = []
    mutex.define_singleton_method(:synchronize) do |&block|
      calls << :synchronize_start
      result = block.call
      calls << :synchronize_end
      result
    end
    calls
  end
end
