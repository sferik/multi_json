# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class LoadAdapterTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_load_adapter_with_symbol
    result = MultiJSON.send(:load_adapter, :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_raises_for_string
    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, "json_gem")
    end

    assert_match(/Symbol or Module/, error.message)
  end

  def test_load_adapter_with_class
    custom_adapter = valid_custom_class
    result = MultiJSON.send(:load_adapter, custom_adapter)

    assert_equal custom_adapter, result
  end

  def test_load_adapter_with_module
    custom_adapter = valid_custom_module
    result = MultiJSON.send(:load_adapter, custom_adapter)

    assert_equal custom_adapter, result
  end

  def test_load_adapter_with_nil_loads_default
    MultiJSON.use :json_gem
    clear_default_adapter_state
    capture_stderr { MultiJSON.default_adapter }

    result = MultiJSON.send(:load_adapter, nil)

    refute_nil result
  end

  def test_load_adapter_with_false_loads_default
    clear_default_adapter_state
    capture_stderr { MultiJSON.default_adapter }

    result = MultiJSON.send(:load_adapter, false)

    refute_nil result
  end

  def test_load_adapter_raises_for_invalid_type
    custom = Object.new
    def custom.inspect = "<custom-inspect>"
    def custom.to_s = "<custom-to-s>"

    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, custom)
    end

    assert_match(/Symbol or Module/, error.message)
    assert_match(/<custom-inspect>/, error.message)
  end

  def test_load_adapter_raises_for_unknown_symbol
    assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, :nonexistent_adapter)
    end
  end

  def test_load_adapter_wraps_load_error
    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.send(:load_adapter, :bad_adapter)
    end

    assert_kind_of LoadError, error.cause
  end

  private

  def clear_default_adapter_state
    MultiJSON.remove_instance_variable(:@default_adapter) if MultiJSON.instance_variable_defined?(:@default_adapter)
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
