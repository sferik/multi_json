# frozen_string_literal: true

require_relative "../../../test_helper"

# These tests use a strict adapter that fails if options are missing/nil.
class StrictAdapterLoadTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_load_passes_string_as_first_argument
    MultiJSON.parse('{"key":"value"}')

    call = TestHelpers::StrictAdapter.parse_calls.first

    assert_equal '{"key":"value"}', call[:string]
  end

  def test_load_passes_options_hash_as_second_argument
    MultiJSON.parse('{"a":1}', symbolize_names: true)

    call = TestHelpers::StrictAdapter.parse_calls.first

    assert call[:options].key?(:symbolize_names)
  end

  def test_load_passes_empty_hash_when_no_options_given
    MultiJSON.parse('{"a":1}')

    call = TestHelpers::StrictAdapter.parse_calls.first

    assert_kind_of Hash, call[:options]
  end

  def test_load_options_not_nil
    MultiJSON.parse('{"a":1}')

    call = TestHelpers::StrictAdapter.parse_calls.first

    refute_nil call[:options], "Options should never be nil"
  end

  def test_load_string_not_nil
    MultiJSON.parse('{"a":1}')

    call = TestHelpers::StrictAdapter.parse_calls.first

    refute_nil call[:string], "String should never be nil"
  end

  def test_load_with_symbolize_names_option
    result = MultiJSON.parse('{"key":"value"}', symbolize_names: true)

    assert_equal({key: "value"}, result)
    call = TestHelpers::StrictAdapter.parse_calls.first

    assert call[:options][:symbolize_names]
  end
end
