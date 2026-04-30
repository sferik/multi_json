# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "adapter_selection_test"

class CurrentAdapterSelectionIntegrationTest < Minitest::Test
  cover "MultiJSON*"

  include IntegrationTestSetup

  def test_current_adapter_defaults_to_current_adapter
    original = MultiJSON.adapter
    MultiJSON.use :json_gem

    assert_equal MultiJSON.adapter, MultiJSON.current_adapter
  ensure
    MultiJSON.use original
  end

  def test_current_adapter_accepts_nil_options
    original = MultiJSON.adapter
    MultiJSON.use :json_gem

    assert_equal MultiJSON.adapter, MultiJSON.current_adapter(nil)
  ensure
    MultiJSON.use original
  end

  def test_current_adapter_respects_adapter_option
    original = MultiJSON.adapter
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::Oj, MultiJSON.current_adapter(adapter: :oj)
  ensure
    MultiJSON.use original
  end

  def test_settable_via_symbol
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_settable_via_case_insensitive_string
    MultiJSON.use "Json_Gem"

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_settable_via_class
    adapter = valid_custom_class
    MultiJSON.use adapter

    assert_equal adapter, MultiJSON.adapter
  end

  def test_settable_via_module
    adapter = valid_custom_module
    MultiJSON.use adapter

    assert_equal adapter, MultiJSON.adapter
  end

  def test_throws_adapter_error_on_bad_input
    assert_raises(MultiJSON::AdapterError) { MultiJSON.use "bad adapter" }
  end

  def test_throws_adapter_error_on_invalid_type
    assert_raises(MultiJSON::AdapterError) { MultiJSON.use 12_345 }
  end

  private

  def valid_custom_class
    Class.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = "{}"
    end
  end

  def valid_custom_module
    Module.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = "{}"
    end
  end
end
