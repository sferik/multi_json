# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class LoadAdapterByNameTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_load_adapter_by_name_requires_adapter_file
    result = MultiJSON.send(:load_adapter_by_name, "json_gem")

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_handles_underscore_names
    result = MultiJSON.send(:load_adapter_by_name, "json_gem")

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_handles_aliases
    skip "JrJackson not available" unless TestHelpers.jrjackson?

    result = MultiJSON.send(:load_adapter_by_name, "jrjackson")

    assert_equal MultiJSON::Adapters::JrJackson, result
  end

  def test_load_adapter_by_name_normalizes_case
    result = MultiJSON.send(:load_adapter_by_name, "JSON_GEM")

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_constructs_class_name
    result = MultiJSON.send(:load_adapter_by_name, "json_gem")

    assert_equal "JsonGem", result.name.split("::").last
  end
end
