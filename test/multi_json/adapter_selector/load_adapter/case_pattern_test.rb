# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class LoadAdapterCasePatternTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_handles_nil_via_nilclass
    clear_default_adapter_state
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJson.send(:load_adapter, nil)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_handles_false_via_falseclass
    clear_default_adapter_state
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJson.send(:load_adapter, false)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_handles_class_objects
    custom_class = Class.new

    result = MultiJson.send(:load_adapter, custom_class)

    assert_equal custom_class, result
  end

  def test_load_adapter_handles_module_objects
    custom_module = Module.new

    result = MultiJson.send(:load_adapter, custom_module)

    assert_equal custom_module, result
  end

  def test_load_adapter_class_returns_class_not_nil
    custom_class = Class.new

    result = MultiJson.send(:load_adapter, custom_class)

    refute_nil result
    assert_equal custom_class, result
  end

  def test_load_adapter_class_pattern_matches_class
    adapter_class = Class.new

    result = MultiJson.send(:load_adapter, adapter_class)

    assert_equal adapter_class, result
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end
