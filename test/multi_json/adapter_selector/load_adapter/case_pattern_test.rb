# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class LoadAdapterCasePatternTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_load_adapter_handles_nil_via_nilclass
    clear_default_adapter_state
    MultiJSON.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJSON.send(:load_adapter, nil)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_handles_false_via_falseclass
    clear_default_adapter_state
    MultiJSON.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJSON.send(:load_adapter, false)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_handles_class_objects
    custom_class = valid_custom_class

    result = MultiJSON.send(:load_adapter, custom_class)

    assert_equal custom_class, result
  end

  def test_load_adapter_handles_module_objects
    custom_module = valid_custom_module

    result = MultiJSON.send(:load_adapter, custom_module)

    assert_equal custom_module, result
  end

  def test_load_adapter_class_returns_class_not_nil
    custom_class = valid_custom_class

    result = MultiJSON.send(:load_adapter, custom_class)

    refute_nil result
    assert_equal custom_class, result
  end

  def test_load_adapter_class_pattern_matches_class
    adapter_class = valid_custom_class

    result = MultiJSON.send(:load_adapter, adapter_class)

    assert_equal adapter_class, result
  end

  private

  def clear_default_adapter_state
    MultiJSON.remove_instance_variable(:@default_adapter) if MultiJSON.instance_variable_defined?(:@default_adapter)
    MultiJSON.remove_instance_variable(:@default_parse_adapter) if MultiJSON.instance_variable_defined?(:@default_parse_adapter)
    MultiJSON.remove_instance_variable(:@default_generate_adapter) if MultiJSON.instance_variable_defined?(:@default_generate_adapter)
  end

  def valid_custom_class
    Class.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.parse(_string, _options) = nil
      def self.generate(_object, _options) = "{}"
    end
  end

  def valid_custom_module
    Module.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.parse(_string, _options) = nil
      def self.generate(_object, _options) = "{}"
    end
  end
end
