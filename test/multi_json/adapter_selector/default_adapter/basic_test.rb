# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

class AdapterSelectorDefaultAdapterTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def test_default_adapter_caches_result
    clear_default_adapter_state

    first_call = capture_stderr { MultiJSON.default_adapter }
    second_call = MultiJSON.default_adapter

    assert_equal first_call, second_call
  end

  def test_default_generate_adapter_caches_result
    clear_default_adapter_state

    first_call = capture_stderr { MultiJSON.default_generate_adapter }
    second_call = MultiJSON.default_generate_adapter

    assert_equal first_call, second_call
  end

  def test_default_adapter_returns_cached_value_when_set
    clear_default_adapter_state
    capture_stderr { MultiJSON.default_adapter }

    assert MultiJSON.instance_variable_defined?(:@default_parse_adapter)
  end

  def test_default_generate_adapter_returns_cached_value_when_set
    clear_default_adapter_state
    capture_stderr { MultiJSON.default_generate_adapter }

    assert MultiJSON.instance_variable_defined?(:@default_generate_adapter)
  end

  def test_default_adapter_returns_supported_parse_adapter
    clear_default_adapter_state

    result = capture_stderr { MultiJSON.default_adapter }

    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_default_generate_adapter_returns_supported_generate_adapter
    clear_default_adapter_state

    result = capture_stderr { MultiJSON.default_generate_adapter }

    assert_includes %i[json_gem oj yajl jr_jackson gson], result
  end

  def test_default_adapter_fallback_to_json_gem
    simulate_no_adapters do
      clear_default_adapter_state
      clear_default_adapter_warning

      result = capture_stderr { MultiJSON.default_adapter }

      assert_equal :json_gem, result
    end
  end

  def test_default_adapter_holds_mutex_during_lazy_init
    clear_default_adapter_state
    mutex = MultiJSON::Concurrency.const_get(:MUTEXES).fetch(:default_adapter)
    synchronized = stub_synchronize_flag(mutex)

    capture_stderr { MultiJSON.default_adapter }

    assert synchronized.value
  ensure
    mutex&.singleton_class&.send(:remove_method, :synchronize)
  end

  private

  def stub_synchronize_flag(mutex)
    flag = Struct.new(:value).new(false)
    mutex.define_singleton_method(:synchronize) do |&block|
      flag.value = true
      block.call
    end
    flag
  end

  def clear_default_adapter_state
    MultiJSON.remove_instance_variable(:@default_adapter) if MultiJSON.instance_variable_defined?(:@default_adapter)
    MultiJSON.remove_instance_variable(:@default_parse_adapter) if MultiJSON.instance_variable_defined?(:@default_parse_adapter)
    MultiJSON.remove_instance_variable(:@default_generate_adapter) if MultiJSON.instance_variable_defined?(:@default_generate_adapter)
  end
end
