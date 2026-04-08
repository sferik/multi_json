require_relative "../../test_helper"

class OptionsCacheTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
    max = MultiJson::OptionsCache.max_cache_size

    (max + 1).times do |i|
      MultiJson::OptionsCache.dump.fetch(key: i) { {foo: i} }
      MultiJson::OptionsCache.load.fetch(key: i) { {foo: i} }
    end
  end

  def test_doesnt_leak_memory
    [MultiJson::OptionsCache.dump, MultiJson::OptionsCache.load].each do |cache|
      size = cache.instance_variable_get(:@cache).size

      assert_operator size, :<=, MultiJson::OptionsCache.max_cache_size
    end
  end

  def test_does_not_store_default_value
    MultiJson::OptionsCache.dump.fetch(:foo, :bar)

    assert_equal :baz, MultiJson::OptionsCache.dump.fetch(:foo, :baz)
  end

  def test_executes_block_only_once_per_key_in_concurrent_access
    MultiJson::OptionsCache.reset
    counter = 0
    # The sleep forces the GVL to yield mid-block so an unsynchronized
    # fetch is observably wrong: every thread would see an empty cache,
    # run the block, and increment counter past 1.
    cache_block = lambda do
      MultiJson::OptionsCache.dump.fetch(:foo) { sleep(0.01) && counter += 1 }
    end
    threads = Array.new(5) { Thread.new(&cache_block) }
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

  def test_concurrent_fetch_returns_consistent_value
    store = MultiJson::OptionsCache::Store.new
    results = concurrent_fetch_results(store, :concurrent_key, 10)

    # All threads should observe the same value (the first one stored)
    assert_equal 1, results.uniq.size
  end

  private

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
