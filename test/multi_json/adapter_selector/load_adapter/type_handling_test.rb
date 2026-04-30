# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

# Tests for load_adapter method behavior
class LoadAdapterTypeHandlingTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_load_adapter_with_string_calls_to_s
    result = MultiJSON.send(:load_adapter, "json_gem")

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_with_symbol_calls_to_s
    result = MultiJSON.send(:load_adapter, :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_with_nil_calls_default_adapter
    clear_default_adapter_state
    MultiJSON.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJSON.send(:load_adapter, nil)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_with_false_calls_default_adapter
    clear_default_adapter_state
    MultiJSON.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJSON.send(:load_adapter, false)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_with_class_returns_class
    custom = valid_custom_adapter
    result = MultiJSON.send(:load_adapter, custom)

    assert_equal custom, result
  end

  def test_load_adapter_with_module_returns_module
    custom = valid_custom_adapter
    result = MultiJSON.send(:load_adapter, custom)

    assert_equal custom, result
  end

  def test_load_adapter_raises_for_custom_adapter_without_load
    custom = adapter_without_load
    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, custom)
    end

    assert_match(/must respond to \.load/, error.message)
    assert_includes error.message, custom.to_s
  end

  def test_load_adapter_raises_for_custom_adapter_without_dump
    custom = adapter_without_dump
    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, custom)
    end

    assert_match(/must respond to \.dump/, error.message)
    assert_includes error.message, custom.to_s
  end

  def test_load_adapter_raises_for_custom_adapter_without_parse_error
    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, adapter_without_parse_error)
    end

    assert_match(/ParseError constant/, error.message)
  end

  def test_load_adapter_raises_for_other_types
    assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, 12_345)
    end
  end

  def test_load_adapter_wraps_load_error_in_adapter_error
    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, "nonexistent")
    end

    assert_kind_of LoadError, error.cause
  end

  private

  def clear_default_adapter_state
    MultiJSON.remove_instance_variable(:@default_adapter) if MultiJSON.instance_variable_defined?(:@default_adapter)
  end

  def valid_custom_adapter
    Module.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = "{}"
    end
  end

  def adapter_without_load
    Module.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.dump(_object, _options) = "{}"
    end
  end

  def adapter_without_dump
    Module.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.load(_string, _options) = nil
    end
  end

  def adapter_without_parse_error
    Module.new do
      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = "{}"
    end
  end
end
