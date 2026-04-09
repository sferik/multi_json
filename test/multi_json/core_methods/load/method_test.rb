# frozen_string_literal: true

require_relative "../../../test_helper"

class LoadMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_without_options_uses_empty_hash
    result = MultiJson.load('{"key": "value"}')

    assert_equal({"key" => "value"}, result)
  end

  def test_load_with_options_passes_them_to_adapter
    result = MultiJson.load('{"key": "value"}', symbolize_keys: true)

    assert_equal({key: "value"}, result)
  end

  def test_load_with_adapter_option_uses_specified_adapter
    MultiJson.use :json_gem
    result = MultiJson.load('{"key": "value"}', adapter: :json_gem)

    assert_equal({"key" => "value"}, result)
    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_load_options_are_not_ignored
    result = MultiJson.load('{"key": "value"}', symbolize_keys: true)

    assert_equal({key: "value"}, result)
  end

  def test_load_options_default_enables_calling_without_second_arg
    result = MultiJson.load('{"test": 123}')

    assert_equal({"test" => 123}, result)
  end

  def test_load_wraps_adapter_parse_error
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{invalid json}")
    end

    assert_equal "{invalid json}", error.data
    refute_nil error.cause
  end

  def test_load_preserves_original_exception_as_cause
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{bad}")
    end

    assert_kind_of Exception, error.cause
  end

  def test_load_uses_current_adapter_for_parsing
    MultiJson.use :json_gem
    result = MultiJson.load('{"a":1}')

    assert_equal({"a" => 1}, result)
  end

  def test_load_passes_string_to_adapter_load
    MultiJson.use :json_gem
    result = MultiJson.load('{"test":"value"}')

    assert_equal({"test" => "value"}, result)
  end

  def test_load_passes_options_to_adapter_load
    MultiJson.use :json_gem
    result = MultiJson.load('{"key":"value"}', symbolize_keys: true)

    assert result.key?(:key)
  end
end
