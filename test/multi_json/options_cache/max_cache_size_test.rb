require_relative "../../test_helper"

# Tests that the cache size limit is configurable at runtime via
# MultiJson::OptionsCache.max_cache_size=.
class OptionsCacheMaxCacheSizeTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    @original_max = MultiJson::OptionsCache.max_cache_size
    MultiJson::OptionsCache.reset
  end

  def teardown
    MultiJson::OptionsCache.max_cache_size = @original_max
    MultiJson::OptionsCache.reset
  end

  def test_default_max_cache_size_matches_constant
    assert_equal MultiJson::OptionsCache::DEFAULT_MAX_CACHE_SIZE,
      MultiJson::OptionsCache.max_cache_size
  end

  def test_setting_max_cache_size_bounds_cache
    MultiJson::OptionsCache.max_cache_size = 5
    store = MultiJson::OptionsCache::Store.new
    20.times { |i| store.fetch(:"k#{i}") { i } }

    cache = store.instance_variable_get(:@cache)

    assert_operator cache.size, :<=, 5
  end

  def test_setting_max_cache_size_returns_new_value
    assert_equal 42, (MultiJson::OptionsCache.max_cache_size = 42)
  end

  def test_raising_max_cache_size_allows_more_entries
    MultiJson::OptionsCache.max_cache_size = 3
    store = MultiJson::OptionsCache::Store.new
    5.times { |i| store.fetch(:"small#{i}") { i } }
    small_size = store.instance_variable_get(:@cache).size

    assert_operator small_size, :<=, 3

    MultiJson::OptionsCache.max_cache_size = 50
    bigger_store = MultiJson::OptionsCache::Store.new
    10.times { |i| bigger_store.fetch(:"big#{i}") { i } }
    bigger_size = bigger_store.instance_variable_get(:@cache).size

    assert_equal 10, bigger_size
  end
end
