# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

# Tests that adapter names are downcased for file paths
class AdapterNameDowncaseTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJSON::AdapterSelector }
    @instance = @test_class.new
  end

  def test_load_adapter_by_name_uses_lowercase_path
    assert_equal "adapters/json_gem", capture_require_relative_path("JSON_GEM")
  end

  def test_load_adapter_by_name_downcases_mixed_case
    assert_equal "adapters/json_gem", capture_require_relative_path("Json_Gem")
  end

  def test_load_adapter_by_name_normalizes_case
    result = @instance.send(:load_adapter_by_name, "JSON_GEM")

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_capitalizes_class_name
    result = @instance.send(:load_adapter_by_name, "json_gem")

    assert_equal "JsonGem", result.name.split("::").last
  end

  def test_load_adapter_by_name_handles_mixed_case
    result = @instance.send(:load_adapter_by_name, "JSON_GEM")

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  private

  def capture_require_relative_path(adapter_name)
    captured_path = nil
    test_module = create_path_capturing_module(->(path) { captured_path = path })
    Object.new.extend(test_module).send(:load_adapter_by_name, adapter_name)
    captured_path
  end

  def create_path_capturing_module(callback)
    ::Module.new do
      include MultiJSON::AdapterSelector

      define_method(:require_relative) do |path|
        callback.call(path)
        ::Kernel.require(File.expand_path("../../../../lib/multi_json/#{path}", __dir__))
      end
    end
  end
end
