# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

# Tests for load_adapter_by_name method
class LoadAdapterByNameConversionTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_load_adapter_by_name_uses_aliases_fetch
    skip "JrJackson not available" unless TestHelpers.jrjackson?

    result = MultiJSON.send(:load_adapter_by_name, "jrjackson")

    assert_equal MultiJSON::Adapters::JrJackson, result
  end

  def test_load_adapter_by_name_uses_name_when_not_aliased
    result = MultiJSON.send(:load_adapter_by_name, "json_gem")

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_downcases_for_require
    result = MultiJSON.send(:load_adapter_by_name, "JSON_GEM")

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_capitalizes_segments
    result = MultiJSON.send(:load_adapter_by_name, "json_gem")

    assert_equal "JsonGem", result.name.split("::").last
  end

  def test_load_adapter_by_name_constructs_correct_class_name
    result = MultiJSON.send(:load_adapter_by_name, "json_gem")

    assert_equal "JsonGem", result.name.split("::").last
  end

  def test_load_adapter_converts_symbol_to_string
    result = MultiJSON.send(:load_adapter, :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_to_s_is_called_on_symbol
    symbol_adapter = :json_gem

    result = MultiJSON.send(:load_adapter, symbol_adapter)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end
end
