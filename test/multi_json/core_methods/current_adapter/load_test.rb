# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for current_adapter method's load_adapter interaction
class CurrentAdapterLoadTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_current_adapter_calls_load_adapter_when_adapter_option_present
    arg_received = with_load_adapter_tracking { MultiJSON.current_adapter(adapter: :json_gem) }

    assert_equal :json_gem, arg_received
  end

  def test_current_adapter_calls_adapter_method_when_no_adapter_option
    adapter_called = with_adapter_tracking { MultiJSON.current_adapter({}) }

    assert adapter_called
  end

  def test_current_adapter_returns_load_adapter_result
    result = MultiJSON.current_adapter(adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_extracts_adapter_from_options_hash
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter({adapter: :json_gem, other: :option})

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  private

  def with_load_adapter_tracking(&)
    arg_received = nil
    stub = ->(arg) { arg_received = arg }
    with_stub(MultiJSON, :load_adapter, stub, call_original: true, &)
    arg_received
  end

  def with_adapter_tracking(&)
    adapter_called = false
    stub = -> { adapter_called = true }
    with_stub(MultiJSON, :adapter, stub, call_original: true, &)
    adapter_called
  end
end
