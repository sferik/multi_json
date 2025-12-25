require_relative "../../test_helper"

# Basic tests for OptionsCache fetch and reset behavior
class OptionsCacheFetchAndResetTest < Minitest::Test
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

  def test_store_adds_to_cache
    store = MultiJson::OptionsCache::Store.new

    store.fetch(:key) { "stored" }

    cache = store.instance_variable_get(:@cache)

    assert_equal "stored", cache[:key]
  end
end
