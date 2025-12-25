require_relative "../../test_helper"

# Tests for the inner fetch race condition check
class OptionsCacheThreadSafetyTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
  end

  def test_inner_fetch_returns_existing_value_from_race
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    # Simulate race condition: key exists in cache before we enter synchronize block
    cache[:race_key] = "existing_value"

    block_executed = false
    result = store.fetch(:race_key) do
      block_executed = true
      "new_value"
    end

    # The inner fetch should find the existing value and return it
    assert_equal "existing_value", result
    refute block_executed, "Block should not execute when key exists from race"
  end

  def test_inner_fetch_uses_correct_key
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    # Set up: nil key has a value, but our target key does not
    cache[nil] = "nil_key_value"

    result = store.fetch(:actual_key) { "block_value" }

    # Should NOT return nil_key_value, should return block value
    assert_equal "block_value", result
    refute_equal "nil_key_value", result
  end

  # Test that inner fetch correctly returns value when key added during lock wait
  def test_inner_fetch_thread_safety
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)

    # Pre-populate cache (simulates another thread winning the race)
    cache[:thread_race] = "winner_value"

    # This should return the existing value, not execute the block
    result = store.fetch(:thread_race) { "loser_value" }

    assert_equal "winner_value", result
  end

  def test_inner_fetch_protects_against_race_during_lock_wait
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    mutex, original = setup_race_condition_mutex(store, cache)

    block_executed, result = execute_fetch_with_race(store)

    assert_equal "injected_by_racing_thread", result
    refute block_executed, "Block should not execute when inner fetch finds existing value"
  ensure
    restore_mutex(mutex, original)
  end

  private

  def setup_race_condition_mutex(store, cache)
    mutex = store.instance_variable_get(:@mutex)
    original = mutex.method(:synchronize)
    silence_warnings do
      mutex.define_singleton_method(:synchronize) do |&block|
        cache[:race_during_lock] = "injected_by_racing_thread"
        original.call(&block)
      end
    end
    [mutex, original]
  end

  def execute_fetch_with_race(store)
    block_executed = false
    result = store.fetch(:race_during_lock) do
      block_executed = true
      "from_block"
    end
    [block_executed, result]
  end

  def restore_mutex(mutex, original)
    silence_warnings { mutex.define_singleton_method(:synchronize, original) } if mutex && original
  end
end
