require_relative "../../test_helper"

# Tests for synchronization behavior
class OptionsCacheSynchronizationTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_fetch_synchronize_is_used
    store = MultiJson::OptionsCache::Store.new
    sync_called = false

    stub_synchronize(store) { sync_called = true }
    store.fetch(:sync_test) { "value" }

    assert sync_called
  end

  def test_reset_uses_mutex_synchronize
    store = MultiJson::OptionsCache::Store.new
    sync_called = false

    stub_synchronize(store) { sync_called = true }
    store.reset

    assert sync_called
  end

  def test_reset_clears_cache
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:key1) { "value1" }
    cache = store.instance_variable_get(:@cache)

    assert_equal 1, cache.size

    store.reset

    assert_equal 0, cache.size
  end

  private

  def stub_synchronize(store)
    mutex = store.instance_variable_get(:@mutex)
    original_sync = mutex.method(:synchronize)

    silence_warnings do
      mutex.define_singleton_method(:synchronize) { |&block| yield && original_sync.call(&block) }
    end
  end
end
