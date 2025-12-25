require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class AdapterSelectorDefaultAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_default_adapter_caches_result
    clear_default_adapter_state

    first_call = capture_stderr { MultiJson.default_adapter }
    second_call = MultiJson.default_adapter

    assert_equal first_call, second_call
  end

  def test_default_adapter_returns_cached_value_when_set
    clear_default_adapter_state
    capture_stderr { MultiJson.default_adapter }

    assert MultiJson.instance_variable_defined?(:@default_adapter)
  end

  def test_default_adapter_prefers_loaded_adapter
    skip unless defined?(::Oj) || defined?(::JSON::Ext::Parser)
    clear_default_adapter_state

    result = capture_stderr { MultiJson.default_adapter }

    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_default_adapter_fallback_to_ok_json
    simulate_no_adapters do
      clear_default_adapter_state
      clear_default_adapter_warning

      result = capture_stderr { MultiJson.default_adapter }

      assert_equal :ok_json, result
    end
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end
