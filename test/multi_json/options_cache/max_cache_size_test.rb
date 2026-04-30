# frozen_string_literal: true

require_relative "../../test_helper"

# Tests that the cache size limit is configurable at runtime via
# MultiJSON::OptionsCache.max_cache_size=.
class OptionsCacheMaxCacheSizeTest < Minitest::Test
  cover "MultiJSON::OptionsCache*"

  def setup
    @original_max = MultiJSON::OptionsCache.max_cache_size
    MultiJSON::OptionsCache.reset
  end

  def teardown
    MultiJSON::OptionsCache.max_cache_size = @original_max
    MultiJSON::OptionsCache.reset
  end

  def test_default_max_cache_size_matches_constant
    assert_equal MultiJSON::OptionsCache::DEFAULT_MAX_CACHE_SIZE,
      MultiJSON::OptionsCache.max_cache_size
  end

  def test_setting_max_cache_size_bounds_cache
    MultiJSON::OptionsCache.max_cache_size = 5
    store = MultiJSON::OptionsCache::Store.new
    20.times { |i| store.fetch(:"k#{i}") { i } }

    cache = store.instance_variable_get(:@cache)

    assert_operator cache.size, :<=, 5
  end

  def test_setting_max_cache_size_returns_new_value
    assert_equal 42, (MultiJSON::OptionsCache.max_cache_size = 42)
  end

  def test_setting_max_cache_size_rejects_nil
    error = assert_raises(ArgumentError) { MultiJSON::OptionsCache.max_cache_size = nil }

    assert_match(/positive Integer/, error.message)
    assert_includes error.message, "nil"
  end

  def test_setting_max_cache_size_rejects_zero
    error = assert_raises(ArgumentError) { MultiJSON::OptionsCache.max_cache_size = 0 }

    assert_match(/positive Integer/, error.message)
    assert_includes error.message, "0"
  end

  def test_setting_max_cache_size_rejects_negative_integer
    error = assert_raises(ArgumentError) { MultiJSON::OptionsCache.max_cache_size = -1 }

    assert_match(/positive Integer/, error.message)
    assert_includes error.message, "-1"
  end

  def test_setting_max_cache_size_rejects_non_integer
    error = assert_raises(ArgumentError) { MultiJSON::OptionsCache.max_cache_size = "10" }

    assert_match(/positive Integer/, error.message)
    assert_includes error.message, '"10"'
  end

  def test_raising_max_cache_size_allows_more_entries
    MultiJSON::OptionsCache.max_cache_size = 3
    store = MultiJSON::OptionsCache::Store.new
    5.times { |i| store.fetch(:"small#{i}") { i } }
    small_size = store.instance_variable_get(:@cache).size

    assert_operator small_size, :<=, 3

    MultiJSON::OptionsCache.max_cache_size = 50
    bigger_store = MultiJSON::OptionsCache::Store.new
    10.times { |i| bigger_store.fetch(:"big#{i}") { i } }
    bigger_size = bigger_store.instance_variable_get(:@cache).size

    assert_equal 10, bigger_size
  end
end
