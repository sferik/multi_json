require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class LoadAdapterByNameTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_by_name_requires_adapter_file
    result = MultiJson.send(:load_adapter_by_name, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_handles_underscore_names
    result = MultiJson.send(:load_adapter_by_name, "ok_json")

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_load_adapter_by_name_handles_aliases
    skip "JrJackson not available" unless TestHelpers.jrjackson?

    result = MultiJson.send(:load_adapter_by_name, "jrjackson")

    assert_equal MultiJson::Adapters::JrJackson, result
  end

  def test_load_adapter_by_name_normalizes_case
    result = MultiJson.send(:load_adapter_by_name, "JSON_GEM")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_constructs_class_name
    result = MultiJson.send(:load_adapter_by_name, "ok_json")

    assert_equal "OkJson", result.name.split("::").last
  end
end
