require_relative "../test_helper"

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

  def test_store_value_returns_existing_when_race_condition
    # This tests the race condition branch at line 36:
    # Value gets stored by another thread between line 23 check and store_value call
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    # We need to trigger the scenario where:
    # 1. Thread A passes line 23 check (key doesn't exist)
    # 2. Thread B adds the key to cache
    # 3. Thread A calls store_value, which checks again at line 36

    # To test this directly, we call store_value via send when key exists
    cache[:direct_key] = "existing_value"
    result = store.send(:store_value, :direct_key, "new_value")

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
    threads.each(&:join)
    results
  end
end

# Basic mutation-killing tests for OptionsCache
class OptionsCacheBasicMutationTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
  end

  def test_fetch_returns_cached_value_not_nil
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:key) { "cached_value" }

    result = store.fetch(:key)

    assert_equal "cached_value", result
  end

  def test_fetch_returns_block_result
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:new_key) { "block_result" }

    assert_equal "block_result", result
  end

  def test_fetch_yields_block_for_missing_key
    store = MultiJson::OptionsCache::Store.new
    yielded = false

    store.fetch(:missing) do
      yielded = true
      "value"
    end

    assert yielded
  end

  def test_fetch_does_not_yield_for_existing_key
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:existing) { "first" }
    yielded = false

    store.fetch(:existing) do
      yielded = true
      "second"
    end

    refute yielded
  end

  def test_fetch_returns_default_when_no_block_and_missing
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:missing, "default_value")

    assert_equal "default_value", result
  end

  def test_fetch_returns_nil_default_when_no_block_and_missing
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:missing)

    assert_nil result
  end

  def test_reset_clears_cache_completely
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:key1) { "value1" }
    store.fetch(:key2) { "value2" }

    store.reset

    assert_nil store.fetch(:key1, nil)
    assert_nil store.fetch(:key2, nil)
  end

  def test_store_value_adds_to_cache
    store = MultiJson::OptionsCache::Store.new

    store.fetch(:key) { "stored" }

    cache = store.instance_variable_get(:@cache)

    assert_equal "stored", cache[:key]
  end
end

# Tests for cache size management
class OptionsCacheSizeTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
  end

  def test_store_value_shifts_when_at_max_size
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

  def test_store_value_checks_cache_size
    store = MultiJson::OptionsCache::Store.new
    max = MultiJson::OptionsCache::MAX_CACHE_SIZE

    # Fill exactly to max
    max.times { |i| store.fetch(:"key#{i}") { "value#{i}" } }

    cache = store.instance_variable_get(:@cache)

    assert_equal max, cache.size
  end
end

# Tests for module-level reset behavior
class OptionsCacheModuleTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
  end

  def test_module_reset_creates_new_stores
    old_dump = MultiJson::OptionsCache.dump
    old_load = MultiJson::OptionsCache.load

    MultiJson::OptionsCache.reset

    refute_same old_dump, MultiJson::OptionsCache.dump
    refute_same old_load, MultiJson::OptionsCache.load
  end

  def test_module_dump_returns_store
    assert_kind_of MultiJson::OptionsCache::Store, MultiJson::OptionsCache.dump
  end

  def test_module_load_returns_store
    assert_kind_of MultiJson::OptionsCache::Store, MultiJson::OptionsCache.load
  end

  def test_module_reset_creates_dump_store
    MultiJson::OptionsCache.reset

    assert_kind_of MultiJson::OptionsCache::Store, MultiJson::OptionsCache.dump
  end

  def test_module_reset_creates_load_store
    MultiJson::OptionsCache.reset

    assert_kind_of MultiJson::OptionsCache::Store, MultiJson::OptionsCache.load
  end
end

# Tests for Store initialization
class OptionsCacheStoreInitTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_store_new_initializes_cache_hash
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    assert_kind_of Hash, cache
  end

  def test_store_new_initializes_mutex
    store = MultiJson::OptionsCache::Store.new
    mutex = store.instance_variable_get(:@mutex)

    assert_kind_of Mutex, mutex
  end

  def test_fetch_uses_cache_key_method
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:test_key) { "test_value" }
    cache = store.instance_variable_get(:@cache)

    assert cache.key?(:test_key)
    assert_equal "test_value", cache[:test_key]
  end
end

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

# Tests for cache lookup behavior
class OptionsCacheLookupTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_fetch_checks_cache_key_before_lock
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:preexisting) { "original" }

    # Second fetch should return cached value without calling block
    result = store.fetch(:preexisting) { "should_not_be_called" }

    assert_equal "original", result
  end

  def test_fetch_checks_cache_key_inside_lock
    # This is tested by the race condition tests above
    # The double-check inside synchronize is for thread safety
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    # Simulate race: key added between first check and lock
    cache[:race] = "from_other_thread"
    result = store.fetch(:race) { "should_not_be_used" }

    assert_equal "from_other_thread", result
  end

  def test_store_value_returns_stored_value
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:key) { "stored" }

    assert_equal "stored", result
  end

  def test_fetch_first_cache_check_returns_cached_value
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:test_key) { "original" }

    block_called = false
    result = store.fetch(:test_key) do
      block_called = true
      "new"
    end

    refute block_called, "Block should not be called when value is cached"
    assert_equal "original", result
  end

  def test_fetch_returns_value_from_cache_bracket_access
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:bracket_test) { "cached_value" }

    result = store.fetch(:bracket_test) { "should_not_use" }

    assert_equal "cached_value", result
  end
end

# Tests for early return optimization
class OptionsCacheEarlyReturnTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_fetch_early_return_skips_synchronize
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:early_return_test) { "value" }

    sync_called = track_synchronize_calls(store) { store.fetch(:early_return_test) { "new_value" } }

    refute sync_called, "synchronize should not be called when cache hit on first check"
  end

  def test_fetch_without_block_returns_default
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:nonexistent, "default_value")

    assert_equal "default_value", result
  end

  def test_fetch_without_block_or_default_returns_nil
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:nonexistent)

    assert_nil result
  end

  def test_fetch_body_executes_not_nil
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:new_key) { "computed" }

    refute_nil result
    assert_equal "computed", result
  end

  # rubocop:disable Style/RedundantFetchBlock
  def test_fetch_stores_and_returns_block_result
    store = MultiJson::OptionsCache::Store.new

    # Block form is required here to test that the value is stored
    result = store.fetch(:compute_key) { 42 }

    assert_equal 42, result
    assert_equal 42, store.fetch(:compute_key) { 999 }
  end
  # rubocop:enable Style/RedundantFetchBlock

  private

  def track_synchronize_calls(store)
    mutex = store.instance_variable_get(:@mutex)
    sync_called = false
    original_sync = mutex.method(:synchronize)

    silence_warnings do
      mutex.define_singleton_method(:synchronize) { |&block| (sync_called = true) && original_sync.call(&block) }
    end

    yield
    sync_called
  ensure
    silence_warnings { mutex.define_singleton_method(:synchronize, original_sync) }
  end
end
