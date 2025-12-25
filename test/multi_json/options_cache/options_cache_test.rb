require_relative "../../test_helper"

class OptionsCacheTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE

    (max + 1).times do |i|
      MultiJson::OptionsCache.dump.fetch(key: i) { {foo: i} }
      MultiJson::OptionsCache.load.fetch(key: i) { {foo: i} }
    end
  end

  def test_doesnt_leak_memory
    caches = [MultiJson::OptionsCache.dump, MultiJson::OptionsCache.load].map do |cache|
      cache.instance_variable_get(:@cache).length
    end

    assert(caches.all? { |c| c == MultiJson::OptionsCache::MAX_CACHE_SIZE })
  end

  def test_stores_value_in_current_cache_after_reset
    MultiJson::OptionsCache.load.fetch(:foo) do
      MultiJson::OptionsCache.reset
      :bar
    end

    assert_equal :baz, MultiJson::OptionsCache.load.fetch(:foo, :baz)
  end

  def test_does_not_store_default_value
    MultiJson::OptionsCache.dump.fetch(:foo, :bar)

    assert_equal :baz, MultiJson::OptionsCache.dump.fetch(:foo, :baz)
  end

  def test_executes_block_only_once_per_key_in_concurrent_access
    MultiJson::OptionsCache.reset
    counter = 0
    threads = Array.new(5) do
      Thread.new { MultiJson::OptionsCache.dump.fetch(:foo) { counter += 1 } }
    end
    threads.each(&:join)

    assert_equal 1, counter
  end

  def test_store_reset_clears_cache
    store = MultiJson::OptionsCache.dump
    store.fetch(:test_key) { "test_value" }

    assert_equal "test_value", store.fetch(:test_key, nil)

    store.reset

    assert_nil store.fetch(:test_key, nil)
  end

  def test_fetch_returns_cached_value_when_added_between_check_and_lock
    # Tests the race condition branch where another thread adds the key
    # between the initial check and acquiring the lock
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    key_added, continue_fetch = setup_mutex_interception(store)

    thread_a = Thread.new { store.fetch(:race_key) { "should_not_be_used" } }

    key_added.pop
    cache[:race_key] = "injected_value"
    continue_fetch.push(:continue)

    assert_equal "injected_value", thread_a.value
  end

  def setup_mutex_interception(store)
    mutex = store.instance_variable_get(:@mutex)
    key_added = Queue.new
    continue_fetch = Queue.new
    original_synchronize = mutex.method(:synchronize)

    mutex.define_singleton_method(:synchronize) do |&block|
      key_added.push(:ready)
      continue_fetch.pop
      original_synchronize.call(&block)
    end

    [key_added, continue_fetch]
  end

  def test_store_returns_existing_when_race_condition
    # This tests the race condition branch at line 36:
    # Value gets stored by another thread between line 23 check and store call
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    # We need to trigger the scenario where:
    # 1. Thread A passes line 23 check (key doesn't exist)
    # 2. Thread B adds the key to cache
    # 3. Thread A calls store, which checks again at line 36

    # To test this directly, we call store via send when key exists
    cache[:direct_key] = "existing_value"
    result = store.send(:store, :direct_key, "new_value")

    # Should return existing value, not store new value
    assert_equal "existing_value", result
    assert_equal "existing_value", cache[:direct_key]
  end

  def test_concurrent_fetch_triggers_race_condition_check
    # Use threads to trigger the race condition path
    store = MultiJson::OptionsCache::Store.new
    results = concurrent_fetch_results(store, :concurrent_key, 10)

    # All threads should get the same value (the first one stored)
    assert_equal 1, results.uniq.size
  end

  def concurrent_fetch_results(store, key, thread_count)
    results = []
    mutex = Mutex.new

    threads = Array.new(thread_count) do
      Thread.new do
        value = store.fetch(key) { Thread.current.object_id }
        mutex.synchronize { results << value }
      end
    end
    threads.each(&:value)
    results
  end
end
