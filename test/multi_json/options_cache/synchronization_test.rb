# frozen_string_literal: true

require_relative "../../test_helper"

# Tests that the cache survives concurrent access without raising or
# returning corrupt values. The store wraps Concurrent::Map, which
# handles synchronization internally.
class OptionsCacheSynchronizationTest < Minitest::Test
  cover "MultiJSON::OptionsCache*"

  def test_reset_clears_cache
    store = MultiJSON::OptionsCache::Store.new
    store.fetch(:key1) { "value1" }
    cache = store.instance_variable_get(:@cache)

    assert_equal 1, cache.size

    store.reset

    assert_equal 0, cache.size
  end

  def test_reset_holds_mutex_during_clear
    store = MultiJSON::OptionsCache::Store.new
    mutex_ivar = (RUBY_ENGINE == "jruby") ? :@eviction_mutex : :@mutex
    mutex = store.instance_variable_get(mutex_ivar)
    calls = stub_mutex_synchronize(mutex)

    store.reset

    assert_equal %i[synchronize_start synchronize_end], calls
  end

  def test_fetch_without_block_holds_mutex_during_lookup
    skip "JRuby ConcurrentStore uses lock-free reads" if RUBY_ENGINE == "jruby"

    store = MultiJSON::OptionsCache::Store.new
    mutex = store.instance_variable_get(:@mutex)
    calls = stub_mutex_synchronize(mutex)

    store.fetch(:missing_key, "default")

    assert_equal %i[synchronize_start synchronize_end], calls
  end

  def test_concurrent_fetches_do_not_raise
    store = MultiJSON::OptionsCache::Store.new

    threads = 10.times.map do |i|
      Thread.new { 100.times { store.fetch(:"k#{i}") { i } } }
    end

    threads.each(&:join)

    cache = store.instance_variable_get(:@cache)

    assert_operator cache.size, :<=, MultiJSON::OptionsCache.max_cache_size
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
