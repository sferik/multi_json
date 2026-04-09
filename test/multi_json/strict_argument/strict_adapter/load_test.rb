# frozen_string_literal: true

require_relative "../../../test_helper"

# These tests use a strict adapter that fails if options are missing/nil.
class StrictAdapterLoadTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_load_passes_string_as_first_argument
    MultiJson.load('{"key":"value"}')

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_equal '{"key":"value"}', call[:string]
  end

  def test_load_passes_options_hash_as_second_argument
    MultiJson.load('{"a":1}', symbolize_keys: true)

    call = TestHelpers::StrictAdapter.load_calls.first

    assert call[:options].key?(:symbolize_keys)
  end

  def test_load_passes_empty_hash_when_no_options_given
    MultiJson.load('{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_kind_of Hash, call[:options]
  end

  def test_load_options_not_nil
    MultiJson.load('{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    refute_nil call[:options], "Options should never be nil"
  end

  def test_load_string_not_nil
    MultiJson.load('{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    refute_nil call[:string], "String should never be nil"
  end

  def test_load_with_symbolize_keys_option
    result = MultiJson.load('{"key":"value"}', symbolize_keys: true)

    assert_equal({key: "value"}, result)
    call = TestHelpers::StrictAdapter.load_calls.first

    assert call[:options][:symbolize_keys]
  end
end
