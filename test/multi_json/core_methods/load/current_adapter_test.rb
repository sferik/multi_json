# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for load method's current_adapter interaction
class LoadCurrentAdapterTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_load_calls_current_adapter_with_options
    opts_received = with_current_adapter_tracking { MultiJSON.load('{"a":1}', symbolize_names: true) }

    assert_equal({symbolize_names: true}, opts_received)
  end

  def test_load_calls_adapter_load_method
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJSON.load('{"test":"value"}')

    assert_equal 1, TestHelpers::StrictAdapter.load_calls.size
    assert_equal '{"test":"value"}', TestHelpers::StrictAdapter.load_calls.first[:string]
  ensure
    MultiJSON.use :json_gem
  end

  def test_load_returns_adapter_load_result
    result = MultiJSON.load('{"key":"value"}')

    assert_equal({"key" => "value"}, result)
  end

  def test_load_catches_adapter_parse_error
    MultiJSON.use :json_gem

    error = assert_raises(MultiJSON::ParseError) do
      MultiJSON.load("{invalid}")
    end

    assert_kind_of MultiJSON::ParseError, error
  end

  def test_load_builds_parse_error_with_data
    error = assert_raises(MultiJSON::ParseError) do
      MultiJSON.load("{bad json}")
    end

    assert_equal "{bad json}", error.data
  end

  def test_load_sets_cause_on_parse_error
    error = assert_raises(MultiJSON::ParseError) do
      MultiJSON.load("{bad}")
    end

    refute_nil error.cause
  end

  private

  def with_current_adapter_tracking(&)
    opts_received = nil
    stub = ->(opts = {}) { opts_received = opts }
    with_stub(MultiJSON, :current_adapter, stub, call_original: true, &)
    opts_received
  end
end
