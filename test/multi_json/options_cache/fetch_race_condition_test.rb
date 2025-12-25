require_relative "../../test_helper"

class OptionsCacheFetchRaceConditionTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_fetch_inner_check_returns_value_when_key_added_during_lock_wait
    # This tests the race condition path where key is added between first check and lock
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    block_executed = false

    # Pre-populate the cache before the block can run
    cache[:race_key] = "existing_from_race"

    result = store.fetch(:race_key) do
      block_executed = true
      "should_not_use_this"
    end

    # The inner check should find the key and return it
    assert_equal "existing_from_race", result
    refute block_executed, "Block should not execute when key exists from race condition"
  end

  def test_fetch_returns_exact_value_not_nil_from_inner_check
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:inner_test] = "specific_value"

    result = store.fetch(:inner_test) { "fallback" }

    assert_equal "specific_value", result
    refute_nil result
  end

  def test_fetch_returns_value_from_bracket_access_not_fetch_method
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:bracket_test] = "bracket_value"

    result = store.fetch(:bracket_test) { "unused" }

    assert_equal "bracket_value", result
  end

  def test_fetch_inner_check_uses_correct_key
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:correct_key] = "correct_value"
    cache[nil] = "nil_key_value"

    result = store.fetch(:correct_key) { "block_value" }

    # Should return value for :correct_key, not nil key
    assert_equal "correct_value", result
    refute_equal "nil_key_value", result
  end

  def test_fetch_inner_check_condition_not_replaced_with_false
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    # Set up the scenario where key exists before lock
    cache[:exists] = "pre_existing"
    block_executed = false

    result = store.fetch(:exists) do
      block_executed = true
      "from_block"
    end

    assert_equal "pre_existing", result
    refute block_executed
  end

  def test_fetch_inner_check_condition_not_replaced_with_nil
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:nil_test] = "existing_value"
    block_executed = false

    result = store.fetch(:nil_test) do
      block_executed = true
      "block_result"
    end

    assert_equal "existing_value", result
    refute block_executed
  end

  def test_fetch_inner_check_not_removed_entirely
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:remove_check_test] = "should_return_this"
    block_count = 0

    result = store.fetch(:remove_check_test) do
      block_count += 1
      "block_result"
    end

    # If inner check is removed, block executes and stores new value
    # With inner check, existing value is returned
    assert_equal "should_return_this", result
    assert_equal 0, block_count
  end

  def test_fetch_inner_return_is_return_not_just_expression
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:return_test] = "early_return_value"
    store_called = track_store_call(store) { store.fetch(:return_test) { "should_not_store" } }

    refute store_called, "store should not be called when returning from inner check"
    assert_equal "early_return_value", cache[:return_test]
  end

  def track_store_call(store)
    called = false
    store.define_singleton_method(:store) { |key, value| (called = true) && super(key, value) }
    yield
    called
  end
end
