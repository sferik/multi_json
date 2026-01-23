require_relative "../../../test_helper"

# Tests for load method's current_adapter interaction
class LoadCurrentAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_calls_current_adapter_with_options
    opts_received = with_current_adapter_tracking { MultiJson.load('{"a":1}', symbolize_keys: true) }

    assert_equal({symbolize_keys: true}, opts_received)
  end

  def test_load_calls_adapter_load_method
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.load('{"test":"value"}')

    assert_equal 1, TestHelpers::StrictAdapter.load_calls.size
    assert_equal '{"test":"value"}', TestHelpers::StrictAdapter.load_calls.first[:string]
  ensure
    MultiJson.use :json_gem
  end

  def test_load_returns_adapter_load_result
    result = MultiJson.load('{"key":"value"}')

    assert_equal({"key" => "value"}, result)
  end

  def test_load_catches_adapter_parse_error
    MultiJson.use :json_gem

    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{invalid}")
    end

    assert_kind_of MultiJson::ParseError, error
  end

  def test_load_builds_parse_error_with_data
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{bad json}")
    end

    assert_equal "{bad json}", error.data
  end

  def test_load_sets_cause_on_parse_error
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{bad}")
    end

    refute_nil error.cause
  end

  private

  def with_current_adapter_tracking(&)
    opts_received = nil
    stub = ->(opts = {}) { opts_received = opts }
    with_stub(MultiJson, :current_adapter, stub, call_original: true, &)
    opts_received
  end
end
