# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class LoadAdapterToStringConversionTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_calls_to_s_on_symbol
    result = MultiJson.send(:load_adapter, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_calls_to_s_on_string
    result = MultiJson.send(:load_adapter, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_by_name_receives_string
    received_arg = track_load_adapter_by_name_arg { MultiJson.send(:load_adapter, :json_gem) }

    assert_kind_of String, received_arg
    assert_equal "json_gem", received_arg
  end

  def track_load_adapter_by_name_arg
    received = nil
    original = MultiJson.method(:load_adapter_by_name)
    silence_warnings { MultiJson.define_singleton_method(:load_adapter_by_name) { |arg| (received = arg) && original.call(arg) } }
    yield
    received
  ensure
    silence_warnings { MultiJson.define_singleton_method(:load_adapter_by_name, original) }
  end
end
