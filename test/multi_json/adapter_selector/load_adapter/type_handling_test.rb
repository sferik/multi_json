require_relative "../../../test_helper"
require "multi_json/adapter_selector"

# Tests for load_adapter method behavior
class LoadAdapterTypeHandlingTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_with_string_calls_to_s
    result = MultiJson.send(:load_adapter, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_symbol_calls_to_s
    result = MultiJson.send(:load_adapter, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_nil_calls_default_adapter
    clear_default_adapter_state
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJson.send(:load_adapter, nil)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_false_calls_default_adapter
    clear_default_adapter_state
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJson.send(:load_adapter, false)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_class_returns_class
    custom = Class.new
    result = MultiJson.send(:load_adapter, custom)

    assert_equal custom, result
  end

  def test_load_adapter_with_module_returns_module
    custom = Module.new
    result = MultiJson.send(:load_adapter, custom)

    assert_equal custom, result
  end

  def test_load_adapter_raises_for_other_types
    assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, 12_345)
    end
  end

  def test_load_adapter_wraps_load_error_in_adapter_error
    error = assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, "nonexistent")
    end

    assert_kind_of LoadError, error.cause
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end
