require_relative "../test_helper"
require "multi_json/adapter_selector"

class AdapterSelectorDefaultAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_default_adapter_caches_result
    clear_default_adapter_state

    first_call = silence_warnings { MultiJson.default_adapter }
    second_call = MultiJson.default_adapter

    assert_equal first_call, second_call
  end

  def test_default_adapter_returns_cached_value_when_set
    clear_default_adapter_state
    silence_warnings { MultiJson.default_adapter }

    assert MultiJson.instance_variable_defined?(:@default_adapter)
  end

  def test_default_adapter_prefers_loaded_adapter
    skip unless defined?(::Oj) || defined?(::JSON::Ext::Parser)
    clear_default_adapter_state

    result = silence_warnings { MultiJson.default_adapter }

    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_default_adapter_fallback_to_ok_json
    simulate_no_adapters do
      clear_default_adapter_state
      clear_default_adapter_warning

      result = silence_warnings { MultiJson.default_adapter }

      assert_equal :ok_json, result
    end
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end

class AdapterSelectorLoadAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_with_symbol
    result = MultiJson.send(:load_adapter, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_string
    result = MultiJson.send(:load_adapter, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_class
    custom_adapter = Class.new
    result = MultiJson.send(:load_adapter, custom_adapter)

    assert_equal custom_adapter, result
  end

  def test_load_adapter_with_module
    custom_adapter = Module.new
    result = MultiJson.send(:load_adapter, custom_adapter)

    assert_equal custom_adapter, result
  end

  def test_load_adapter_with_nil_loads_default
    MultiJson.use :json_gem
    clear_default_adapter_state
    silence_warnings { MultiJson.default_adapter }

    result = MultiJson.send(:load_adapter, nil)

    refute_nil result
  end

  def test_load_adapter_with_false_loads_default
    clear_default_adapter_state
    silence_warnings { MultiJson.default_adapter }

    result = MultiJson.send(:load_adapter, false)

    refute_nil result
  end

  def test_load_adapter_raises_for_invalid_type
    assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, 12_345)
    end
  end

  def test_load_adapter_raises_for_unknown_string
    assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, "nonexistent_adapter")
    end
  end

  def test_load_adapter_wraps_load_error
    error = assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, "bad_adapter")
    end

    assert_kind_of LoadError, error.cause
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end

class AdapterSelectorLoadAdapterFromStringNameTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_from_string_name_requires_adapter_file
    result = MultiJson.send(:load_adapter_from_string_name, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_from_string_name_handles_underscore_names
    result = MultiJson.send(:load_adapter_from_string_name, "ok_json")

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_load_adapter_from_string_name_handles_aliases
    skip "JrJackson not available" unless TestHelpers.jrjackson?

    result = MultiJson.send(:load_adapter_from_string_name, "jrjackson")

    assert_equal MultiJson::Adapters::JrJackson, result
  end

  def test_load_adapter_from_string_name_normalizes_case
    result = MultiJson.send(:load_adapter_from_string_name, "JSON_GEM")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_from_string_name_constructs_class_name
    result = MultiJson.send(:load_adapter_from_string_name, "ok_json")

    assert_equal "OkJson", result.name.split("::").last
  end
end

class AdapterSelectorLoadedAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_loaded_adapter_detects_fast_jsonparser
    skip unless defined?(::FastJsonparser)
    undefine_constants(:Oj, :Yajl, :JrJackson) do
      result = MultiJson.send(:loaded_adapter)

      assert_equal :fast_jsonparser, result
    end
  end

  def test_loaded_adapter_detects_oj
    skip unless defined?(::Oj)
    undefine_constants(:FastJsonparser) do
      result = MultiJson.send(:loaded_adapter)

      assert_equal :oj, result
    end
  end

  def test_loaded_adapter_detects_yajl
    skip unless defined?(::Yajl)
    undefine_constants(:FastJsonparser, :Oj) do
      result = MultiJson.send(:loaded_adapter)

      assert_equal :yajl, result
    end
  end

  def test_loaded_adapter_returns_nil_when_none_loaded
    simulate_no_adapters do
      result = MultiJson.send(:loaded_adapter)

      assert_nil result
    end
  end

  def test_loaded_adapter_priority_order
    # First available wins
    skip unless defined?(::Oj)
    undefine_constants(:FastJsonparser) do
      result = MultiJson.send(:loaded_adapter)

      assert_equal :oj, result
    end
  end
end

class AdapterSelectorInstallableAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_installable_adapter_tries_requirement_map
    # This test verifies installable_adapter iterates through REQUIREMENT_MAP
    result = MultiJson.send(:installable_adapter)

    # Should find at least one installable adapter
    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_installable_adapter_returns_nil_when_none_installable
    break_requirements do
      result = MultiJson.send(:installable_adapter)

      assert_nil result
    end
  end

  def test_installable_adapter_requires_library
    # The adapter should be requireable after installable_adapter finds it
    result = MultiJson.send(:installable_adapter)

    refute_nil result
  end
end

class AdapterSelectorFallbackAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_fallback_adapter_returns_ok_json
    result = MultiJson.send(:fallback_adapter)

    assert_equal :ok_json, result
  end

  def test_fallback_adapter_shows_warning
    clear_default_adapter_warning
    warned = false

    with_stub(Kernel, :warn, ->(_) { warned = true }) do
      MultiJson.send(:fallback_adapter)
    end

    assert warned
  end

  def test_fallback_adapter_warns_only_once
    clear_default_adapter_warning
    warn_count = 0

    with_stub(Kernel, :warn, ->(_) { warn_count += 1 }) do
      MultiJson.send(:fallback_adapter)
      MultiJson.send(:fallback_adapter)
    end

    assert_equal 1, warn_count
  end

  def test_fallback_adapter_sets_warning_shown_flag
    clear_default_adapter_warning

    silence_warnings { MultiJson.send(:fallback_adapter) }

    assert MultiJson.instance_variable_get(:@default_adapter_warning_shown)
  end
end

class AdapterSelectorAliasesTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_aliases_contains_jrjackson
    assert MultiJson::AdapterSelector::ALIASES.key?("jrjackson")
  end

  def test_aliases_maps_jrjackson_to_jr_jackson
    assert_equal "jr_jackson", MultiJson::AdapterSelector::ALIASES["jrjackson"]
  end

  def test_aliases_is_frozen
    assert_predicate MultiJson::AdapterSelector::ALIASES, :frozen?
  end
end

# Tests for default_adapter caching and storage behavior
class AdapterSelectorDefaultAdapterMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_default_adapter_returns_cached_value
    clear_default_adapter_state
    first = silence_warnings { MultiJson.default_adapter }
    second = MultiJson.default_adapter

    assert_equal first, second
  end

  def test_default_adapter_stores_result
    clear_default_adapter_state
    silence_warnings { MultiJson.default_adapter }

    assert MultiJson.instance_variable_defined?(:@default_adapter)
  end

  def test_default_adapter_uses_loaded_adapter_first
    skip unless defined?(::Oj) || defined?(::JSON::Ext::Parser)
    clear_default_adapter_state

    result = silence_warnings { MultiJson.default_adapter }

    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_default_adapter_tries_loaded_before_installable
    clear_default_adapter_state

    result = silence_warnings { MultiJson.default_adapter }

    refute_nil result
    assert_kind_of Symbol, result
  end

  def test_default_adapter_falls_back_to_installable
    simulate_no_adapters do
      clear_default_adapter_state

      result = silence_warnings { MultiJson.default_adapter }

      assert_equal :ok_json, result
    end
  end

  def test_default_adapter_falls_back_to_fallback_adapter
    simulate_no_adapters do
      break_requirements do
        clear_default_adapter_state

        result = silence_warnings { MultiJson.default_adapter }

        assert_equal :ok_json, result
      end
    end
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end

# Tests for load_adapter method behavior
class AdapterSelectorLoadAdapterMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_with_string_calls_to_s
    result = MultiJson.send(:load_adapter, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_symbol_calls_to_s
    result = MultiJson.send(:load_adapter, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_nil_calls_default_adapter
    clear_default_adapter_state
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJson.send(:load_adapter, nil)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_false_calls_default_adapter
    clear_default_adapter_state
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJson.send(:load_adapter, false)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_with_class_returns_class
    custom = Class.new
    result = MultiJson.send(:load_adapter, custom)

    assert_equal custom, result
  end

  def test_load_adapter_with_module_returns_module
    custom = Module.new
    result = MultiJson.send(:load_adapter, custom)

    assert_equal custom, result
  end

  def test_load_adapter_raises_for_other_types
    assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, 12_345)
    end
  end

  def test_load_adapter_wraps_load_error_in_adapter_error
    error = assert_raises(MultiJson::AdapterError) do
      MultiJson.send(:load_adapter, "nonexistent")
    end

    assert_kind_of LoadError, error.cause
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end

# Tests for load_adapter_from_string_name method
class AdapterSelectorStringNameMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_load_adapter_from_string_name_uses_aliases_fetch
    skip "JrJackson not available" unless TestHelpers.jrjackson?

    result = MultiJson.send(:load_adapter_from_string_name, "jrjackson")

    assert_equal MultiJson::Adapters::JrJackson, result
  end

  def test_load_adapter_from_string_name_uses_name_when_not_aliased
    result = MultiJson.send(:load_adapter_from_string_name, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_from_string_name_downcases_for_require
    result = MultiJson.send(:load_adapter_from_string_name, "JSON_GEM")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_from_string_name_capitalizes_segments
    result = MultiJson.send(:load_adapter_from_string_name, "ok_json")

    assert_equal "OkJson", result.name.split("::").last
  end

  def test_load_adapter_from_string_name_constructs_correct_class_name
    result = MultiJson.send(:load_adapter_from_string_name, "ok_json")

    assert_equal "OkJson", result.name.split("::").last
  end
end

# Tests for loaded_adapter and installable_adapter methods
class AdapterSelectorAdapterDetectionMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_loaded_adapter_returns_nil_when_none_defined
    simulate_no_adapters do
      result = MultiJson.send(:loaded_adapter)

      assert_nil result
    end
  end

  def test_installable_adapter_iterates_requirement_map
    result = MultiJson.send(:installable_adapter)

    refute_nil result
  end

  def test_installable_adapter_returns_nil_when_none_installable
    break_requirements do
      result = MultiJson.send(:installable_adapter)

      assert_nil result
    end
  end
end

# Tests for fallback_adapter method and warning behavior
class AdapterSelectorFallbackMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_fallback_adapter_returns_ok_json
    clear_default_adapter_warning

    result = silence_warnings { MultiJson.send(:fallback_adapter) }

    assert_equal :ok_json, result
  end

  def test_fallback_adapter_calls_kernel_warn
    clear_default_adapter_warning
    warned = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_| warned = true } }

    MultiJson.send(:fallback_adapter)

    assert warned
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_fallback_adapter_sets_warning_shown_flag
    clear_default_adapter_warning

    silence_warnings { MultiJson.send(:fallback_adapter) }

    assert MultiJson.instance_variable_get(:@default_adapter_warning_shown)
  end

  def test_fallback_adapter_only_warns_once
    clear_default_adapter_warning
    warn_count = 0
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_| warn_count += 1 } }

    MultiJson.send(:fallback_adapter)
    MultiJson.send(:fallback_adapter)

    assert_equal 1, warn_count
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_fallback_adapter_warning_message_not_nil
    clear_default_adapter_warning
    warning_received = nil
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |msg| warning_received = msg } }

    MultiJson.send(:fallback_adapter)

    refute_nil warning_received, "Warning message should not be nil"
    assert_includes warning_received, "MultiJson"
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end
end
