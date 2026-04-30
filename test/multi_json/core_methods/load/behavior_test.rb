# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for load method behavior
class LoadBehaviorTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_load_returns_parsed_value_not_nil
    result = MultiJSON.load('{"key":"value"}')

    refute_nil result
    assert_equal({"key" => "value"}, result)
  end

  def test_load_body_executes
    result = MultiJSON.load('{"test":123}')

    refute_nil result
    assert_kind_of Hash, result
  end

  def test_load_uses_passed_options_not_empty_hash
    MultiJSON.use :json_gem
    result = MultiJSON.load('{"key":"value"}', symbolize_names: true)

    assert result.key?(:key), "Options should be used, not replaced with {}"
    refute result.key?("key"), "Keys should be symbolized"
  end

  def test_load_uses_current_adapter_result_not_options
    result = MultiJSON.load('{"a":1}', {symbolize_names: false})

    assert_kind_of Hash, result
  end

  def test_load_uses_current_adapter_result_not_nil
    result = MultiJSON.load('{"a":1}')

    refute_nil result
  end

  def test_load_does_not_call_super
    assert_equal({"works" => true}, MultiJSON.load('{"works":true}'))
  end

  def test_load_error_cause_is_original_exception
    error = assert_raises(MultiJSON::ParseError) { MultiJSON.load("{invalid}") }

    refute_nil error.cause, "cause should be the original exception, not nil"
    assert_kind_of StandardError, error.cause
  end

  def test_load_raises_parse_error_not_just_raise
    error = assert_raises(MultiJSON::ParseError) { MultiJSON.load("{bad json}") }

    assert_kind_of MultiJSON::ParseError, error
    assert_equal "{bad json}", error.data
  end

  def test_load_rescue_catches_adapter_error
    error = assert_raises(MultiJSON::ParseError) { MultiJSON.load("not valid json") }

    assert_kind_of MultiJSON::ParseError, error
    refute_nil error.cause
  end

  def test_load_error_data_is_original_string
    error = assert_raises(MultiJSON::ParseError) { MultiJSON.load("bad json string") }

    assert_equal "bad json string", error.data
  end

  def test_load_passes_options_containing_adapter_to_current_adapter
    adapter_received = track_current_adapter_options { MultiJSON.load('{"key":"value"}', adapter: :json_gem) }

    assert_equal :json_gem, adapter_received
  end

  def test_load_returns_adapter_load_result_not_adapter
    result = MultiJSON.load('{"key":"value"}')

    assert_kind_of Hash, result
    refute_kind_of Module, result
  end

  def test_load_calls_load_not_dump
    result = MultiJSON.load('{"key":"value"}')

    # load returns parsed data, dump would return a string from the string input
    assert_kind_of Hash, result
    refute_kind_of String, result
  end

  def test_load_passes_string_as_first_arg
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJSON.load('{"test":1}', {opt: true})

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_equal '{"test":1}', call[:string]
    assert_equal({opt: true}, call[:options])
  ensure
    MultiJSON.use :json_gem
  end

  def test_load_passes_options_as_second_arg
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJSON.load('{"a":1}', {my_option: "value"})

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_equal({my_option: "value"}, call[:options])
  ensure
    MultiJSON.use :json_gem
  end

  def test_load_without_options_passes_empty_hash_not_nil
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    # StrictAdapter raises ArgumentError if options is nil
    # This test ensures the default parameter is {} not nil
    MultiJSON.load('{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_kind_of Hash, call[:options]
  ensure
    MultiJSON.use :json_gem
  end
end
