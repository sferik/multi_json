# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class DefaultAdapterDefinedCheckTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_default_adapter_uses_defined_check
    clear_default_adapter_state

    first = capture_stderr { MultiJSON.default_adapter }
    second = MultiJSON.default_adapter

    assert_equal first, second
    assert MultiJSON.instance_variable_defined?(:@default_adapter)
  end

  def test_default_adapter_returns_early_when_cached
    clear_default_adapter_state
    first_result = capture_stderr { MultiJSON.default_adapter }

    loaded_adapter_called = track_loaded_adapter_call { MultiJSON.default_adapter }

    refute loaded_adapter_called, "loaded_adapter should not be called when @default_adapter is defined"
    assert_equal first_result, MultiJSON.default_adapter
  end

  def track_loaded_adapter_call
    called = false
    original = MultiJSON.method(:loaded_adapter)
    silence_warnings { MultiJSON.define_singleton_method(:loaded_adapter) { (called = true) && original.call } }
    yield
    called
  ensure
    silence_warnings { MultiJSON.define_singleton_method(:loaded_adapter, original) }
  end

  private

  def clear_default_adapter_state
    MultiJSON.remove_instance_variable(:@default_adapter) if MultiJSON.instance_variable_defined?(:@default_adapter)
  end
end
