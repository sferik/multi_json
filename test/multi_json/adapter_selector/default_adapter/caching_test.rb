# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

# Tests for default_adapter caching and storage behavior
class DefaultAdapterCachingTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_default_adapter_returns_cached_value
    clear_default_adapter_state
    first = capture_stderr { MultiJSON.default_adapter }
    second = MultiJSON.default_adapter

    assert_equal first, second
  end

  def test_default_adapter_stores_result
    clear_default_adapter_state
    capture_stderr { MultiJSON.default_adapter }

    assert MultiJSON.instance_variable_defined?(:@default_adapter)
  end

  def test_default_adapter_uses_loaded_adapter_first
    skip unless defined?(::Oj) || defined?(::JSON::Ext::Parser)
    clear_default_adapter_state

    result = capture_stderr { MultiJSON.default_adapter }

    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_default_adapter_tries_loaded_before_installable
    clear_default_adapter_state

    result = capture_stderr { MultiJSON.default_adapter }

    refute_nil result
    assert_kind_of Symbol, result
  end

  def test_default_adapter_falls_back_to_installable
    simulate_no_adapters do
      clear_default_adapter_state

      result = capture_stderr { MultiJSON.default_adapter }

      assert_equal :json_gem, result
    end
  end

  def test_default_adapter_falls_back_to_fallback_adapter
    simulate_no_adapters do
      break_requirements do
        clear_default_adapter_state

        result = capture_stderr { MultiJSON.default_adapter }

        assert_equal :json_gem, result
      end
    end
  end

  private

  def clear_default_adapter_state
    MultiJSON.remove_instance_variable(:@default_adapter) if MultiJSON.instance_variable_defined?(:@default_adapter)
  end
end
