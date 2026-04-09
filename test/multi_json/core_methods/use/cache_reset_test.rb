# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for use method cache reset behavior
class UseCacheResetTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_use_calls_options_cache_reset_not_nil
    key = :"use_test_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached_before" }

    assert_equal "cached_before", MultiJson::OptionsCache.dump.fetch(key, nil)

    MultiJson.use(:json_gem)

    # After use, cache should be cleared
    # If OptionsCache.reset was replaced with nil, cache would NOT be cleared
    assert_nil MultiJson::OptionsCache.dump.fetch(key, nil), "Cache should be cleared after use"
  end

  def test_use_calls_reset_method_on_options_cache
    key = :"reset_test_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached_before" }

    MultiJson.use(:json_gem)

    # OptionsCache (the module) would not clear the cache
    # OptionsCache.reset (the method) clears the cache
    assert_nil MultiJson::OptionsCache.dump.fetch(key, nil)
  end

  def test_use_preserves_cache_when_load_adapter_raises
    key = :"ensure_test_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached" }

    assert_raises(MultiJson::AdapterError) do
      MultiJson.use("nonexistent_adapter_12345")
    end

    # The previous adapter is still active, so its cache must survive the
    # failed swap.
    assert_equal "cached", MultiJson::OptionsCache.dump.fetch(key, nil)
  end
end
