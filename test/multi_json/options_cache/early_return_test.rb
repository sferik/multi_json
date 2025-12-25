require_relative "../../test_helper"

# Tests for early return optimization
class OptionsCacheEarlyReturnTest < Minitest::Test
  cover "MultiJson::OptionsCache*"

  def test_fetch_early_return_skips_synchronize
    store = MultiJson::OptionsCache::Store.new
    store.fetch(:early_return_test) { "value" }

    sync_called = track_synchronize_calls(store) { store.fetch(:early_return_test) { "new_value" } }

    refute sync_called, "synchronize should not be called when cache hit on first check"
  end

  def test_fetch_without_block_returns_default
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:nonexistent, "default_value")

    assert_equal "default_value", result
  end

  def test_fetch_without_block_or_default_returns_nil
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:nonexistent)

    assert_nil result
  end

  def test_fetch_body_executes_not_nil
    store = MultiJson::OptionsCache::Store.new

    result = store.fetch(:new_key) { "computed" }

    refute_nil result
    assert_equal "computed", result
  end

  # rubocop:disable Style/RedundantFetchBlock
  def test_fetch_stores_and_returns_block_result
    store = MultiJson::OptionsCache::Store.new

    # Block form is required here to test that the value is stored
    result = store.fetch(:compute_key) { 42 }

    assert_equal 42, result
    assert_equal 42, store.fetch(:compute_key) { 999 }
  end
  # rubocop:enable Style/RedundantFetchBlock

  private

  def track_synchronize_calls(store)
    mutex = store.instance_variable_get(:@mutex)
    sync_called = false
    original_sync = mutex.method(:synchronize)

    silence_warnings do
      mutex.define_singleton_method(:synchronize) { |&block| (sync_called = true) && original_sync.call(&block) }
    end

    yield
    sync_called
  ensure
    silence_warnings { mutex.define_singleton_method(:synchronize, original_sync) }
  end
end
