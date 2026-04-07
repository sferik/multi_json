require_relative "../../test_helper"

# Tests that fetch consistently returns existing values even when keys
# are inserted by another thread between the lookup and the compute step.
# Concurrent::Map's compute_if_absent provides this guarantee internally.
class OptionsCacheFetchRaceConditionTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_fetch_returns_existing_value_when_pre_populated
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:race_key] = "existing_from_race"
    block_executed = false

    result = store.fetch(:race_key) do
      block_executed = true
      "should_not_use_this"
    end

    assert_equal "existing_from_race", result
    refute block_executed
  end

  def test_fetch_returns_specific_value_not_nil
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:inner_test] = "specific_value"

    result = store.fetch(:inner_test) { "fallback" }

    assert_equal "specific_value", result
    refute_nil result
  end

  def test_fetch_uses_correct_key
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:correct_key] = "correct_value"
    cache[nil] = "nil_key_value"

    result = store.fetch(:correct_key) { "block_value" }

    assert_equal "correct_value", result
    refute_equal "nil_key_value", result
  end

  def test_fetch_skips_block_when_value_already_present
    store = MultiJson::OptionsCache::Store.new
    cache = store.instance_variable_get(:@cache)
    cache[:exists] = "pre_existing"
    block_executed = false

    result = store.fetch(:exists) do
      block_executed = true
      "from_block"
    end

    assert_equal "pre_existing", result
    refute block_executed
  end
end
