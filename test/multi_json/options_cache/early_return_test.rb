# frozen_string_literal: true

require_relative "../../test_helper"

# Tests for the no-block fetch path
class OptionsCacheEarlyReturnTest < Minitest::Test
  cover "MultiJSON::OptionsCache*"

  def test_fetch_without_block_returns_default
    store = MultiJSON::OptionsCache::Store.new

    result = store.fetch(:nonexistent, "default_value")

    assert_equal "default_value", result
  end

  def test_fetch_without_block_or_default_returns_nil
    store = MultiJSON::OptionsCache::Store.new

    result = store.fetch(:nonexistent)

    assert_nil result
  end

  def test_fetch_body_executes_not_nil
    store = MultiJSON::OptionsCache::Store.new

    result = store.fetch(:new_key) { "computed" }

    refute_nil result
    assert_equal "computed", result
  end

  def test_fetch_stores_and_returns_block_result
    store = MultiJSON::OptionsCache::Store.new

    # Block form is required here to test that the value is stored
    result = store.fetch(:compute_key) { 42 }

    assert_equal 42, result
    assert_equal 42, store.fetch(:compute_key) { 999 }
  end
end
