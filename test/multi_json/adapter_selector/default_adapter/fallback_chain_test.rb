# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class DefaultAdapterFallbackChainTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_default_adapter_uses_loaded_adapter_when_available
    clear_default_adapter_state

    result = capture_stderr { MultiJSON.default_adapter }

    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_default_adapter_falls_back_to_installable_when_none_loaded
    simulate_no_adapters do
      clear_default_adapter_state
      result = capture_stderr { MultiJSON.default_adapter }

      assert_equal :json_gem, result
    end
  end

  def test_default_adapter_uses_installable_not_nil_when_loaded_returns_nil
    simulate_no_adapters do
      clear_default_adapter_state

      result = capture_stderr { MultiJSON.default_adapter }

      assert_equal :json_gem, result
    end
  end

  def test_default_adapter_calls_both_loaded_and_installable_when_loaded_returns_nil
    simulate_no_adapters do
      break_requirements do
        clear_default_adapter_state
        loaded_called, installable_called = track_adapter_methods_called

        assert loaded_called, "loaded_adapter should be called"
        assert installable_called, "installable_adapter should be called when loaded_adapter returns nil"
      end
    end
  end

  def track_adapter_methods_called
    loaded = false
    installable = false
    with_adapter_method_tracking(:loaded_adapter, -> { loaded = true }) do
      with_adapter_method_tracking(:installable_adapter, -> { installable = true }) do
        capture_stderr { MultiJSON.default_adapter }
      end
    end
    [loaded, installable]
  end

  private

  def clear_default_adapter_state
    MultiJSON.remove_instance_variable(:@default_adapter) if MultiJSON.instance_variable_defined?(:@default_adapter)
    MultiJSON.remove_instance_variable(:@default_parse_adapter) if MultiJSON.instance_variable_defined?(:@default_parse_adapter)
    MultiJSON.remove_instance_variable(:@default_generate_adapter) if MultiJSON.instance_variable_defined?(:@default_generate_adapter)
    clear_default_adapter_warning
  end

  def with_adapter_method_tracking(method_name, tracker)
    original = MultiJSON.method(method_name)
    silence_warnings do
      MultiJSON.define_singleton_method(method_name) do |*args, **kwargs|
        tracker.call
        original.call(*args, **kwargs)
      end
    end
    yield
  ensure
    silence_warnings { MultiJSON.define_singleton_method(method_name, original) }
  end
end
