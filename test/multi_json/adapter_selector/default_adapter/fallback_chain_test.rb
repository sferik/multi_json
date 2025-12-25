require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class DefaultAdapterFallbackChainTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_default_adapter_uses_loaded_adapter_when_available
    skip unless defined?(::Oj) || defined?(::JSON::Ext::Parser)
    clear_default_adapter_state

    result = capture_stderr { MultiJson.default_adapter }

    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_default_adapter_falls_back_to_installable_when_none_loaded
    simulate_no_adapters do
      clear_default_adapter_state
      result = capture_stderr { MultiJson.default_adapter }

      assert_equal :ok_json, result
    end
  end

  def test_default_adapter_uses_installable_not_nil_when_loaded_returns_nil
    simulate_no_adapters do
      clear_default_adapter_state

      result = capture_stderr { MultiJson.default_adapter }

      assert_equal :ok_json, result
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
        capture_stderr { MultiJson.default_adapter }
      end
    end
    [loaded, installable]
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
    clear_default_adapter_warning
  end

  def with_adapter_method_tracking(method_name, tracker)
    original = MultiJson.method(method_name)
    silence_warnings do
      MultiJson.define_singleton_method(method_name) do
        tracker.call
        original.call
      end
    end
    yield
  ensure
    silence_warnings { MultiJson.define_singleton_method(method_name, original) }
  end
end
