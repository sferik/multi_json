# frozen_string_literal: true

require_relative "../../test_helper"

class UseReturnValueAndCacheResetTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    @original = MultiJSON.adapter
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_use_returns_loaded_adapter
    result = MultiJSON.use(:json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
    refute_nil result
  end

  def test_use_calls_load_adapter
    called = track_load_adapter_calls { MultiJSON.use(:json_gem) }

    assert called
  end

  private

  def track_load_adapter_calls(&)
    load_adapter_called = false
    original = MultiJSON.method(:load_adapter)
    stub = lambda do |arg|
      load_adapter_called = true
      original.call(arg)
    end
    with_stub(MultiJSON, :load_adapter, stub, &)
    load_adapter_called
  end

  public

  def test_use_stores_adapter
    MultiJSON.use(:json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.instance_variable_get(:@adapter)
  end

  def test_use_resets_options_cache
    MultiJSON::OptionsCache.dump.fetch(:test_key) { "value" }

    MultiJSON.use(:json_gem)

    assert_nil MultiJSON::OptionsCache.dump.fetch(:test_key, nil)
  end

  def test_use_preserves_cache_on_error
    MultiJSON::OptionsCache.dump.fetch(:error_test) { "cached" }

    assert_raises(MultiJSON::AdapterError) do
      MultiJSON.use("nonexistent")
    end

    assert_equal "cached", MultiJSON::OptionsCache.dump.fetch(:error_test, nil)
  end
end
