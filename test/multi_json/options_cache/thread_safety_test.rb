require_relative "../../test_helper"

# Tests for cache behavior under concurrent access. Concurrent::Map
# handles synchronization internally; we verify only the externally
# visible contract.
class OptionsCacheThreadSafetyTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def setup
    MultiJson::OptionsCache.reset
  end

  def test_existing_value_wins_over_compute_block
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:race_key] = "existing_value"

    block_executed = false
    result = store.fetch(:race_key) do
      block_executed = true
      "new_value"
    end

    assert_equal "existing_value", result
    refute block_executed
  end

  def test_fetch_with_specific_key_does_not_collide_with_nil_key
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[nil] = "nil_key_value"

    result = store.fetch(:actual_key) { "block_value" }

    assert_equal "block_value", result
    refute_equal "nil_key_value", result
  end

  def test_concurrent_writers_observe_consistent_value
    store = MultiJson::OptionsCache::Store.new
    threads = Array.new(20) do
      Thread.new { store.fetch(:hot_key) { Thread.current.object_id } }
    end
    values = threads.map(&:value)

    assert_equal 1, values.uniq.size
  end
end
