require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class LoadAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_with_symbol
    result = MultiJson.send(:load_adapter, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_string
    result = MultiJson.send(:load_adapter, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_class
    custom_adapter = Class.new
    result = MultiJson.send(:load_adapter, custom_adapter)

    assert_equal custom_adapter, result
  end

  def test_load_adapter_with_module
    custom_adapter = Module.new
    result = MultiJson.send(:load_adapter, custom_adapter)

    assert_equal custom_adapter, result
  end

  def test_load_adapter_with_nil_loads_default
    MultiJson.use :json_gem
    clear_default_adapter_state
    capture_stderr { MultiJson.default_adapter }

    result = MultiJson.send(:load_adapter, nil)

    refute_nil result
  end

  def test_load_adapter_with_false_loads_default
    clear_default_adapter_state
    capture_stderr { MultiJson.default_adapter }

    result = MultiJson.send(:load_adapter, false)

    refute_nil result
  end

  def test_load_adapter_raises_for_invalid_type
    assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, 12_345)
    end
  end

  def test_load_adapter_raises_for_unknown_string
    assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, "nonexistent_adapter")
    end
  end

  def test_load_adapter_wraps_load_error
    error = assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, "bad_adapter")
    end

    assert_kind_of LoadError, error.cause
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end
