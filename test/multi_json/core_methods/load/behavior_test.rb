require_relative "../../../test_helper"

# Tests for load method behavior
class LoadBehaviorTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_returns_parsed_value_not_nil
    result = MultiJson.load('{"key":"value"}')

    refute_nil result
    assert_equal({"key" => "value"}, result)
  end

  def test_load_body_executes
    result = MultiJson.load('{"test":123}')

    refute_nil result
    assert_kind_of Hash, result
  end

  def test_load_uses_passed_options_not_empty_hash
    MultiJson.use :json_gem
    result = MultiJson.load('{"key":"value"}', symbolize_keys: true)

    assert result.key?(:key), "Options should be used, not replaced with {}"
    refute result.key?("key"), "Keys should be symbolized"
  end

  def test_load_uses_current_adapter_result_not_options
    result = MultiJson.load('{"a":1}', {symbolize_keys: false})

    assert_kind_of Hash, result
  end

  def test_load_uses_current_adapter_result_not_nil
    result = MultiJson.load('{"a":1}')

    refute_nil result
  end

  def test_load_does_not_call_super
    assert_equal({"works" => true}, MultiJson.load('{"works":true}'))
  end

  def test_load_error_cause_is_original_exception
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{invalid}") }

    refute_nil error.cause, "cause should be the original exception, not nil"
    assert_kind_of StandardError, error.cause
  end

  def test_load_raises_parse_error_not_just_raise
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{bad json}") }

    assert_kind_of MultiJson::ParseError, error
    assert_equal "{bad json}", error.data
  end

  def test_load_rescue_catches_adapter_error
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("not valid json") }

    assert_kind_of MultiJson::ParseError, error
    refute_nil error.cause
  end

  def test_load_error_data_is_original_string
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("bad json string") }

    assert_equal "bad json string", error.data
  end

  def test_load_passes_options_containing_adapter_to_current_adapter
    adapter_received = track_current_adapter_options { MultiJson.load('{"key":"value"}', adapter: :json_gem) }

    assert_equal :json_gem, adapter_received
  end

  def test_load_returns_adapter_load_result_not_adapter
    result = MultiJson.load('{"key":"value"}')

    assert_kind_of Hash, result
    refute_kind_of Module, result
  end

  def test_load_calls_load_not_dump
    result = MultiJson.load('{"key":"value"}')

    # load returns parsed data, dump would return a string from the string input
    assert_kind_of Hash, result
    refute_kind_of String, result
  end

  def test_load_passes_string_as_first_arg
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.load('{"test":1}', {opt: true})

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_equal '{"test":1}', call[:string]
    assert_equal({opt: true}, call[:options])
  ensure
    MultiJson.use :json_gem
  end

  def test_load_passes_options_as_second_arg
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.load('{"a":1}', {my_option: "value"})

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_equal({my_option: "value"}, call[:options])
  ensure
    MultiJson.use :json_gem
  end

  def test_load_without_options_passes_empty_hash_not_nil
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    # StrictAdapter raises ArgumentError if options is nil
    # This test ensures the default parameter is {} not nil
    MultiJson.load('{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_kind_of Hash, call[:options]
  ensure
    MultiJson.use :json_gem
  end
end
