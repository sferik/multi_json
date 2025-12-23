require_relative "../test_helper"

class OptionsCacheTest < Minitest::Test
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
end
