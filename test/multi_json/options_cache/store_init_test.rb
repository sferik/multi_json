require_relative "../../test_helper"

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
