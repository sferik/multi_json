# frozen_string_literal: true

require_relative "../../test_helper"

# Tests for cache lookup behavior
class OptionsCacheLookupTest < Minitest::Test
  cover "MultiJSON::OptionsCache*"

  def test_fetch_checks_cache_key_before_lock
    store = MultiJSON::OptionsCache::Store.new
    store.fetch(:preexisting) { "original" }

    # Second fetch should return cached value without calling block
    result = store.fetch(:preexisting) { "should_not_be_called" }

    assert_equal "original", result
  end

  def test_fetch_fast_path_returns_value_for_correct_key
    store = MultiJSON::OptionsCache::Store.new
    store.fetch(:key_a) { "value_a" }
    store.fetch(:key_b) { "value_b" }

    assert_equal "value_a", store.fetch(:key_a)
    assert_equal "value_b", store.fetch(:key_b)
    refute_equal store.fetch(:key_a), store.fetch(:key_b)
  end

  def test_fetch_fast_path_distinguishes_nil_key
    store = MultiJSON::OptionsCache::Store.new
    store.fetch(:key_a) { "value_a" }
    store.fetch(nil) { "nil_value" }

    assert_equal "nil_value", store.fetch(nil)
    refute_equal store.fetch(:key_a), store.fetch(nil)
  end

  def test_fetch_fast_path_returns_nil_value_correctly
    store = MultiJSON::OptionsCache::Store.new
    # Block form required to store nil value in cache
    store.fetch(:nil_val_key) { nil }

    # Fast path should return nil, not re-execute block
    block_called = false
    result = store.fetch(:nil_val_key) do
      block_called = true
      "new_val"
    end

    refute block_called
    assert_nil result
  end

  def test_fetch_checks_cache_key_inside_lock
    # This is tested by the race condition tests above
    # The double-check inside synchronize is for thread safety
    store = MultiJSON::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    # Simulate race: key added between first check and lock
    cache[:race] = "from_other_thread"
    result = store.fetch(:race) { "should_not_be_used" }

    assert_equal "from_other_thread", result
  end

  def test_store_returns_stored_value
    store = MultiJSON::OptionsCache::Store.new

    result = store.fetch(:key) { "stored" }

    assert_equal "stored", result
  end

  def test_fetch_first_cache_check_returns_cached_value
    store = MultiJSON::OptionsCache::Store.new
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
    store = MultiJSON::OptionsCache::Store.new
    store.fetch(:bracket_test) { "cached_value" }

    result = store.fetch(:bracket_test) { "should_not_use" }

    assert_equal "cached_value", result
  end

  def test_fetch_returns_correct_cached_value_not_nil
    store = MultiJSON::OptionsCache::Store.new
    store.fetch(:specific_val) { "the_specific_value" }

    result = store.fetch(:specific_val)

    assert_equal "the_specific_value", result
    refute_nil result
  end

  def test_fetch_first_check_returns_value_immediately
    store = MultiJSON::OptionsCache::Store.new
    store.fetch(:immediate) { "immediate_value" }

    # This tests that the first check (before synchronize) returns the value
    result = store.fetch(:immediate)

    assert_equal "immediate_value", result
  end

  def test_fetch_inside_lock_returns_cached_value
    store = MultiJSON::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:inside_lock] = "lock_value"

    result = store.fetch(:inside_lock) { "block_value" }

    assert_equal "lock_value", result
  end
end
