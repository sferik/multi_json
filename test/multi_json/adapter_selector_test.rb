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

module LoadedAdapterTestHelpers
  def with_temporary_constant(name)
    was_defined = Object.const_defined?(name)
    Object.const_set(name, Module.new) unless was_defined
    yield
  ensure
    Object.send(:remove_const, name) unless was_defined
  end

  def with_json_ext_parser
    return yield if defined?(::JSON::Ext::Parser)

    Object.const_set(:JSON, Module.new) unless Object.const_defined?(:JSON)
    JSON.const_set(:Ext, Module.new) unless JSON.const_defined?(:Ext)
    JSON::Ext.const_set(:Parser, Class.new)
    yield
  ensure
    JSON::Ext.send(:remove_const, :Parser) if defined?(JSON::Ext::Parser)
  end

  def without_json_ext_parser
    return yield unless defined?(::JSON::Ext::Parser)

    parser = JSON::Ext::Parser
    JSON::Ext.send(:remove_const, :Parser)
    yield
  ensure
    JSON::Ext.const_set(:Parser, parser) if parser
  end
end

class AdapterSelectorLoadedAdapterTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"
  include LoadedAdapterTestHelpers

  def test_loaded_adapter_detects_fast_jsonparser
    skip unless defined?(::FastJsonparser)

    undefine_constants(:Oj, :Yajl, :JrJackson) do
      assert_equal :fast_jsonparser, MultiJson.send(:loaded_adapter)
    end
  end

  def test_loaded_adapter_detects_oj
    skip unless defined?(::Oj)

    undefine_constants(:FastJsonparser) { assert_equal :oj, MultiJson.send(:loaded_adapter) }
  end

  def test_loaded_adapter_detects_yajl
    skip unless defined?(::Yajl)

    undefine_constants(:FastJsonparser, :Oj) { assert_equal :yajl, MultiJson.send(:loaded_adapter) }
  end

  def test_loaded_adapter_returns_nil_when_none_loaded
    simulate_no_adapters { assert_nil MultiJson.send(:loaded_adapter) }
  end

  def test_loaded_adapter_detects_jr_jackson_when_defined
    undefine_constants(:FastJsonparser, :Oj, :Yajl) do
      with_temporary_constant(:JrJackson) { assert_equal :jr_jackson, MultiJson.send(:loaded_adapter) }
    end
  end

  def test_loaded_adapter_detects_json_gem_when_defined
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      with_json_ext_parser { assert_equal :json_gem, MultiJson.send(:loaded_adapter) }
    end
  end

  def test_loaded_adapter_detects_gson_when_defined
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      without_json_ext_parser do
        with_temporary_constant(:Gson) { assert_equal :gson, MultiJson.send(:loaded_adapter) }
      end
    end
  end
end

class AdapterSelectorLoadedAdapterPriorityTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"
  include LoadedAdapterTestHelpers

  def test_fast_jsonparser_takes_priority_over_oj
    skip unless defined?(::FastJsonparser) && defined?(::Oj)

    assert_equal :fast_jsonparser, MultiJson.send(:loaded_adapter)
  end

  def test_oj_takes_priority_over_yajl
    skip unless defined?(::Oj) && defined?(::Yajl)

    undefine_constants(:FastJsonparser) { assert_equal :oj, MultiJson.send(:loaded_adapter) }
  end

  def test_yajl_takes_priority_over_jr_jackson
    skip unless defined?(::Yajl)
    undefine_constants(:FastJsonparser, :Oj) do
      with_temporary_constant(:JrJackson) { assert_equal :yajl, MultiJson.send(:loaded_adapter) }
    end
  end

  def test_jr_jackson_takes_priority_over_json_gem
    undefine_constants(:FastJsonparser, :Oj, :Yajl) do
      with_temporary_constant(:JrJackson) { assert_equal :jr_jackson, MultiJson.send(:loaded_adapter) }
    end
  end

  def test_json_gem_takes_priority_over_gson
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      with_json_ext_parser do
        with_temporary_constant(:Gson) { assert_equal :json_gem, MultiJson.send(:loaded_adapter) }
      end
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

  def test_load_adapter_converts_symbol_to_string
    # Kill mutation: new_adapter.to_s -> new_adapter
    # Symbol needs to be converted to string for load_adapter_from_string_name
    result = MultiJson.send(:load_adapter, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_to_s_is_called_on_symbol
    # Kill mutation: new_adapter.to_s -> new_adapter
    # This explicitly tests that to_s is called, which is required for load_adapter_from_string_name
    symbol_adapter = :ok_json

    result = MultiJson.send(:load_adapter, symbol_adapter)

    assert_equal MultiJson::Adapters::OkJson, result
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
class AdapterSelectorDefinedMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  # Kill mutations: defined?(@default_adapter) -> instance_variable_defined?(:@default_adapter)

  def test_default_adapter_uses_defined_check
    # The defined? check and instance_variable_defined? behave identically for this case
    # We verify caching works correctly with either check
    clear_default_adapter_state

    first = silence_warnings { MultiJson.default_adapter }
    second = MultiJson.default_adapter

    assert_equal first, second
    assert MultiJson.instance_variable_defined?(:@default_adapter)
  end

  def test_default_adapter_returns_early_when_cached
    clear_default_adapter_state
    first_result = silence_warnings { MultiJson.default_adapter }

    loaded_adapter_called = track_loaded_adapter_call { MultiJson.default_adapter }

    refute loaded_adapter_called, "loaded_adapter should not be called when @default_adapter is defined"
    assert_equal first_result, MultiJson.default_adapter
  end

  def track_loaded_adapter_call
    called = false
    original = MultiJson.method(:loaded_adapter)
    silence_warnings { MultiJson.define_singleton_method(:loaded_adapter) { (called = true) && original.call } }
    yield
    called
  ensure
    silence_warnings { MultiJson.define_singleton_method(:loaded_adapter, original) }
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end

class AdapterSelectorOrOperatorMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  # Kill mutations in: loaded_adapter || installable_adapter
  # Mutations: loaded_adapter || installable_adapter -> loaded_adapter
  #            loaded_adapter || installable_adapter -> nil || installable_adapter
  #            loaded_adapter || installable_adapter -> loaded_adapter || nil
  #            loaded_adapter || installable_adapter -> installable_adapter

  def test_default_adapter_uses_loaded_adapter_when_available
    skip unless defined?(::Oj) || defined?(::JSON::Ext::Parser)
    clear_default_adapter_state

    result = silence_warnings { MultiJson.default_adapter }

    # loaded_adapter should return a symbol when adapters are loaded
    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_default_adapter_falls_back_to_installable_when_none_loaded
    simulate_no_adapters do
      clear_default_adapter_state
      # installable_adapter will try to require adapters
      result = silence_warnings { MultiJson.default_adapter }

      # Should eventually get ok_json as fallback since no adapters can be required
      assert_equal :ok_json, result
    end
  end

  def test_default_adapter_uses_installable_not_nil_when_loaded_returns_nil
    simulate_no_adapters do
      clear_default_adapter_state

      # With no adapters defined, loaded_adapter returns nil
      # installable_adapter should be called (though it will also fail and fall back)
      result = silence_warnings { MultiJson.default_adapter }

      # The mutation loaded_adapter || nil would cause a fallback to fallback_adapter
      # The mutation nil || installable_adapter would work but skip loaded_adapter
      # Both should eventually result in :ok_json
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
        silence_warnings { MultiJson.default_adapter }
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

class AdapterSelectorCasePatternMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  # Kill mutations in case patterns:
  # when NilClass, FalseClass -> when nil, FalseClass
  # when Class, Module -> when Module
  # when Class, Module -> when nil, Module

  def test_load_adapter_handles_nil_via_nilclass
    clear_default_adapter_state
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJson.send(:load_adapter, nil)

    # nil should match NilClass pattern
    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_handles_false_via_falseclass
    clear_default_adapter_state
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    result = MultiJson.send(:load_adapter, false)

    # false should match FalseClass pattern
    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_handles_class_objects
    custom_class = Class.new

    result = MultiJson.send(:load_adapter, custom_class)

    # Class should match when Class, Module pattern
    assert_equal custom_class, result
  end

  def test_load_adapter_handles_module_objects
    custom_module = Module.new

    result = MultiJson.send(:load_adapter, custom_module)

    # Module should match when Class, Module pattern
    assert_equal custom_module, result
  end

  def test_load_adapter_class_returns_class_not_nil
    # Kill mutation: when Class, Module -> when nil, Module
    custom_class = Class.new

    result = MultiJson.send(:load_adapter, custom_class)

    # If pattern was when nil, Module, a Class would fall through to else (raise)
    refute_nil result
    assert_equal custom_class, result
  end

  def test_load_adapter_class_pattern_matches_class
    # Kill mutation: when Class, Module -> when Module
    # A Class is also a Module, but we want to ensure Class objects work
    adapter_class = Class.new

    # This should not raise - Class should be accepted
    result = MultiJson.send(:load_adapter, adapter_class)

    assert_equal adapter_class, result
  end

  private

  def clear_default_adapter_state
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end
end

class AdapterSelectorToSMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  # Kill mutation: new_adapter.to_s -> new_adapter

  def test_load_adapter_calls_to_s_on_symbol
    # If to_s is not called, load_adapter_from_string_name receives a symbol
    # which would fail differently
    result = MultiJson.send(:load_adapter, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_calls_to_s_on_string
    result = MultiJson.send(:load_adapter, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_load_adapter_from_string_name_receives_string
    received_arg = track_load_adapter_from_string_name_arg { MultiJson.send(:load_adapter, :ok_json) }

    assert_kind_of String, received_arg
    assert_equal "ok_json", received_arg
  end

  def track_load_adapter_from_string_name_arg
    received = nil
    original = MultiJson.method(:load_adapter_from_string_name)
    silence_warnings { MultiJson.define_singleton_method(:load_adapter_from_string_name) { |arg| (received = arg) && original.call(arg) } }
    yield
    received
  ensure
    silence_warnings { MultiJson.define_singleton_method(:load_adapter_from_string_name, original) }
  end
end

class AdapterSelectorInstallableAdapterMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  # Kill mutation: MultiJson::REQUIREMENT_MAP.each -> REQUIREMENT_MAP.each

  def test_installable_adapter_uses_multijson_requirement_map
    # Both should work equivalently, but this verifies the method runs correctly
    result = MultiJson.send(:installable_adapter)

    # Should find at least one adapter that can be required
    refute_nil result
    assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], result
  end

  def test_installable_adapter_iterates_requirement_map
    # Verify that installable_adapter uses REQUIREMENT_MAP by checking result
    result = MultiJson.send(:installable_adapter)

    # If it iterates through REQUIREMENT_MAP, it should find an adapter
    refute_nil result
    assert_includes MultiJson::REQUIREMENT_MAP.keys, result
  end
end

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

# Tests via instance methods (using include) to kill mutations on instance methods
# Mutant uses module_eval which only updates instance methods
class AdapterSelectorInstanceMethodMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  def teardown
    remove_instance_var(:@default_adapter)
    remove_instance_var(:@default_adapter_warning_shown)
  end

  def remove_instance_var(name)
    @instance.remove_instance_variable(name) if @instance.instance_variable_defined?(name)
  end

  # Kill mutation: defined?(@default_adapter) -> instance_variable_defined?(:@default_adapter)

  def test_instance_default_adapter_returns_cached_when_defined
    @instance.instance_variable_set(:@default_adapter, :json_gem)

    result = @instance.default_adapter

    assert_equal :json_gem, result
  end

  def test_instance_default_adapter_computes_when_not_defined
    @instance.remove_instance_variable(:@default_adapter) if @instance.instance_variable_defined?(:@default_adapter)

    result = silence_warnings { @instance.default_adapter }

    refute_nil result
    assert_kind_of Symbol, result
  end

  def test_instance_default_adapter_caches_computed_value
    @instance.remove_instance_variable(:@default_adapter) if @instance.instance_variable_defined?(:@default_adapter)

    silence_warnings { @instance.default_adapter }

    assert @instance.instance_variable_defined?(:@default_adapter)
  end

  # Kill mutation: loaded_adapter || installable_adapter -> loaded_adapter

  def test_instance_default_adapter_falls_back_to_installable
    simulate_no_adapters do
      @instance.remove_instance_variable(:@default_adapter) if @instance.instance_variable_defined?(:@default_adapter)

      result = silence_warnings { @instance.default_adapter }

      # Should fall back to ok_json
      assert_equal :ok_json, result
    end
  end

  # Kill mutation: when NilClass, FalseClass -> when nil, FalseClass

  def test_instance_load_adapter_handles_nil
    @instance.instance_variable_set(:@default_adapter, :json_gem)

    result = @instance.send(:load_adapter, nil)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_instance_load_adapter_handles_false
    @instance.instance_variable_set(:@default_adapter, :json_gem)

    result = @instance.send(:load_adapter, false)

    assert_equal MultiJson::Adapters::JsonGem, result
  end
end

# Additional tests specifically designed to kill mutations on the instance methods
class AdapterSelectorInstanceMutationKillerTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  def teardown
    remove_ivar(:@default_adapter)
    remove_ivar(:@default_adapter_warning_shown)
  end

  def remove_ivar(name)
    @instance.remove_instance_variable(name) if @instance.instance_variable_defined?(name)
  end

  # Tests moved from AdapterSelectorInstanceMethodMutationTest for class length

  def test_instance_load_adapter_handles_class
    assert_equal (c = Class.new), @instance.send(:load_adapter, c)
  end

  def test_instance_load_adapter_handles_module
    assert_equal (m = Module.new), @instance.send(:load_adapter, m)
  end

  def test_instance_load_adapter_raises_with_adapter_in_message
    error = assert_raises(MultiJson::AdapterError) { @instance.send(:load_adapter, 12_345) }

    assert_kind_of LoadError, error.cause
  end

  def test_instance_installable_adapter_uses_requirement_map
    result = @instance.send(:installable_adapter)

    refute_nil result
    assert_includes MultiJson::REQUIREMENT_MAP.keys, result
  end

  def test_instance_load_adapter_from_string_name_with_symbol
    assert_equal MultiJson::Adapters::JsonGem, @instance.send(:load_adapter_from_string_name, "json_gem")
  end

  def test_instance_load_adapter_from_string_name_uses_aliases
    skip "JrJackson not available" unless TestHelpers.jrjackson?

    assert_equal MultiJson::Adapters::JrJackson, @instance.send(:load_adapter_from_string_name, "jrjackson")
  end

  def test_instance_load_adapter_from_string_name_downcases
    assert_equal MultiJson::Adapters::JsonGem, @instance.send(:load_adapter_from_string_name, "JSON_GEM")
  end

  def test_instance_load_adapter_from_string_name_uses_multijson_adapters
    result = @instance.send(:load_adapter_from_string_name, "ok_json")

    assert_equal MultiJson::Adapters::OkJson, result
    assert_equal "MultiJson::Adapters::OkJson", result.name
  end

  def test_instance_loaded_adapter_returns_nil_when_none_defined
    simulate_no_adapters { assert_nil @instance.send(:loaded_adapter) }
  end

  def test_instance_loaded_adapter_returns_symbol_when_found
    skip unless defined?(::Oj) || defined?(::JSON::Ext::Parser)

    result = @instance.send(:loaded_adapter)

    assert_kind_of Symbol, result
    refute_nil result
  end

  # Kill mutation: raise(::LoadError, new_adapter) -> raise(::LoadError)
  def test_instance_load_adapter_error_includes_adapter_value
    error = assert_raises(MultiJson::AdapterError) { @instance.send(:load_adapter, 99_999) }

    assert_kind_of LoadError, error.cause
    assert_includes error.cause.message, "99999"
  end

  # Kill mutation: raise(::LoadError, nil) instead of raise(::LoadError, new_adapter)
  def test_instance_load_adapter_error_message_not_nil
    error = assert_raises(MultiJson::AdapterError) { @instance.send(:load_adapter, "bad_type_here") }

    refute_nil error.cause.message
    refute_empty error.cause.message
  end

  def test_instance_load_adapter_error_has_cause
    error = assert_raises(MultiJson::AdapterError) { @instance.send(:load_adapter, :nonexistent) }

    assert_kind_of LoadError, error.cause
  end

  def test_instance_load_adapter_error_is_built_correctly
    error = assert_raises(MultiJson::AdapterError) { @instance.send(:load_adapter, :nonexistent) }

    assert_kind_of MultiJson::AdapterError, error
  end

  def test_instance_require_relative_uses_downcase
    assert_equal MultiJson::Adapters::OkJson, @instance.send(:load_adapter_from_string_name, "OK_JSON")
  end

  def test_instance_loaded_adapter_explicit_nil_return
    simulate_no_adapters { assert_nil @instance.send(:loaded_adapter) }
  end

  # Kill mutation: raise(AdapterError.build(e)) -> raise(AdapterError)
  def test_instance_load_adapter_error_is_built_from_exception
    error = assert_raises(MultiJson::AdapterError) { @instance.send(:load_adapter, :nonexistent_adapter) }

    # AdapterError.build(e) creates an error with a message like "Did not recognize..."
    # If mutation changes to raise(AdapterError), message would just be the class name
    assert_includes error.message, "Did not recognize", "Error message should come from build()"
  end
end

# Tests that kill namespace mutations by defining conflicting constants
# Mutations: ::MultiJson::REQUIREMENT_MAP -> REQUIREMENT_MAP
#            ::MultiJson::REQUIREMENT_MAP -> MultiJson::REQUIREMENT_MAP
#            ::MultiJson::Adapters -> Adapters
#            ::MultiJson::Adapters -> MultiJson::Adapters
class AdapterSelectorNamespaceMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  def teardown
    remove_conflicting_constants
  end

  # Kill mutation: ::MultiJson::REQUIREMENT_MAP -> REQUIREMENT_MAP
  # By defining a conflicting REQUIREMENT_MAP in AdapterSelector, the bare constant lookup
  # would find the wrong constant and fail, while ::MultiJson::REQUIREMENT_MAP still works.
  def test_installable_adapter_uses_absolute_namespace_for_requirement_map
    define_conflicting_requirement_map

    result = @instance.send(:installable_adapter)

    # Original code uses ::MultiJson::REQUIREMENT_MAP, should find a valid adapter
    # Mutation would use bare REQUIREMENT_MAP, finding our fake one and returning nil
    refute_nil result, "installable_adapter should use ::MultiJson::REQUIREMENT_MAP, not bare REQUIREMENT_MAP"
    assert_includes MultiJson::REQUIREMENT_MAP.keys, result
  end

  # Kill mutation: ::MultiJson::REQUIREMENT_MAP -> MultiJson::REQUIREMENT_MAP
  # By defining a nested MultiJson module in AdapterSelector with its own REQUIREMENT_MAP
  def test_installable_adapter_uses_absolute_not_relative_multijson
    define_nested_multijson_with_requirement_map

    result = @instance.send(:installable_adapter)

    # Original code uses ::MultiJson::REQUIREMENT_MAP (absolute path)
    # Mutation would use MultiJson::REQUIREMENT_MAP which finds the nested one first
    refute_nil result, "installable_adapter should use ::MultiJson (absolute), not relative MultiJson"
    assert_includes ::MultiJson::REQUIREMENT_MAP.keys, result
  end

  # Kill mutation: ::MultiJson::Adapters -> Adapters
  # By defining a conflicting Adapters in AdapterSelector scope
  def test_load_adapter_from_string_name_uses_absolute_namespace_for_adapters
    define_conflicting_adapters

    result = @instance.send(:load_adapter_from_string_name, "ok_json")

    # Original code uses ::MultiJson::Adapters.const_get, should get the real adapter
    # Mutation would use bare Adapters.const_get, finding our fake module
    assert_equal ::MultiJson::Adapters::OkJson, result
    assert_equal "MultiJson::Adapters::OkJson", result.name
  end

  # Kill mutation: ::MultiJson::Adapters -> MultiJson::Adapters
  # By defining a nested MultiJson module in AdapterSelector with its own Adapters
  def test_load_adapter_from_string_name_uses_absolute_not_relative_multijson
    define_nested_multijson_with_adapters

    result = @instance.send(:load_adapter_from_string_name, "ok_json")

    # Original code uses ::MultiJson::Adapters (absolute path)
    # Mutation would use MultiJson::Adapters which finds the nested one first
    assert_equal ::MultiJson::Adapters::OkJson, result
    assert_equal "MultiJson::Adapters::OkJson", result.name
  end

  private

  def define_conflicting_requirement_map
    return if MultiJson::AdapterSelector.const_defined?(:REQUIREMENT_MAP, false)

    MultiJson::AdapterSelector.const_set(:REQUIREMENT_MAP, {bad: "nonexistent_gem"}.freeze)
  end

  def define_conflicting_adapters
    return if MultiJson::AdapterSelector.const_defined?(:Adapters, false)

    fake_adapters = Module.new do
      def self.const_get(_name)
        Module.new # Return a fake module that won't match the real adapter
      end
    end
    MultiJson::AdapterSelector.const_set(:Adapters, fake_adapters)
  end

  def define_nested_multijson_with_requirement_map
    return if MultiJson::AdapterSelector.const_defined?(:MultiJson, false)

    nested = Module.new
    nested.const_set(:REQUIREMENT_MAP, {bad: "nonexistent_gem"}.freeze)
    MultiJson::AdapterSelector.const_set(:MultiJson, nested)
  end

  def define_nested_multijson_with_adapters
    return if MultiJson::AdapterSelector.const_defined?(:MultiJson, false)

    fake_adapters = Module.new do
      def self.const_get(_name)
        Module.new # Return a fake module
      end
    end
    nested = Module.new
    nested.const_set(:Adapters, fake_adapters)
    MultiJson::AdapterSelector.const_set(:MultiJson, nested)
  end

  def remove_conflicting_constants
    remove_const_if_defined(:REQUIREMENT_MAP)
    remove_const_if_defined(:Adapters)
    remove_const_if_defined(:MultiJson)
  end

  def remove_const_if_defined(const_name)
    return unless MultiJson::AdapterSelector.const_defined?(const_name, false)

    MultiJson::AdapterSelector.send(:remove_const, const_name)
  end
end

# Tests that kill ALIASES.fetch mutation
# Mutation: ALIASES.fetch(name, name) -> ALIASES.fetch(nil, name)
class AdapterSelectorAliasesFetchMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  # Kill mutation: ALIASES.fetch(name, name) -> ALIASES.fetch(nil, name)
  # With "jrjackson", original returns "jr_jackson", mutation returns "jrjackson"
  # The file is at adapters/jr_jackson.rb, so mutation would fail to load it
  def test_load_adapter_from_string_name_uses_alias_key_not_nil
    skip "jrjackson gem is available on JRuby so no LoadError is raised" if java?
    error = assert_raises(LoadError) { @instance.send(:load_adapter_from_string_name, "jrjackson") }

    # Original code: ALIASES.fetch("jrjackson", "jrjackson") returns "jr_jackson"
    # Then requires "adapters/jr_jackson" which exists, then requires "jrjackson" gem (fails)
    # Mutation: ALIASES.fetch(nil, "jrjackson") returns "jrjackson"
    # Then requires "adapters/jrjackson" which does NOT exist (different error)

    # The error message should mention "jrjackson" (the gem), NOT "adapters/jrjackson" (nonexistent file)
    refute_includes(
      error.message, "adapters/jrjackson",
      "Should use alias 'jr_jackson' not original 'jrjackson' for file path"
    )
  end
end

# Tests that kill module_loader_if_module mutations
# Mutation: adapter.is_a?(::Module) -> adapter.instance_of?(::Module)
# Mutation: adapter.is_a?(::Module) -> adapter.is_a?(Module)
class AdapterSelectorModuleLoaderMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  # Kill mutation: adapter.is_a?(::Module) -> adapter.instance_of?(::Module)
  # Class inherits from Module, so Class.new.is_a?(Module) is true
  # but Class.new.instance_of?(Module) is false
  def test_load_adapter_handles_class_via_is_a_module
    custom_class = Class.new

    result = @instance.send(:load_adapter, custom_class)

    # If code used instance_of?(Module), Class would fail
    # because Class.new.instance_of?(Module) is false
    assert_equal custom_class, result
  end

  # Kill mutation: adapter.is_a?(::Module) -> adapter.is_a?(Module)
  # Define a conflicting Module constant in AdapterSelector's namespace
  # so relative lookup finds the wrong one
  def test_load_adapter_uses_absolute_module_reference
    # Create a fake Module in AdapterSelector's namespace
    fake_module = Object.new.tap do |fake|
      fake.define_singleton_method(:===) { |_| false }
      fake.define_singleton_method(:name) { "FakeModule" }
    end
    MultiJson::AdapterSelector.const_set(:Module, fake_module)

    custom_module = ::Module.new
    result = @instance.send(:load_adapter, custom_module)

    # If code used relative Module, our fake would return false for is_a?
    assert_equal custom_module, result
  ensure
    MultiJson::AdapterSelector.send(:remove_const, :Module) if MultiJson::AdapterSelector.const_defined?(:Module, false)
  end

  # Verify that Module instances also work
  def test_load_adapter_handles_module_instance
    custom_module = ::Module.new

    result = @instance.send(:load_adapter, custom_module)

    assert_equal custom_module, result
  end
end

# Tests that kill downcase mutation
# Mutation: normalized_name.downcase -> normalized_name
# We verify that require_relative receives a lowercase path
class AdapterSelectorDowncaseMutationTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  # Kill mutation: normalized_name.downcase -> normalized_name
  def test_load_adapter_from_string_name_uses_lowercase_path
    assert_equal "adapters/ok_json", capture_require_relative_path("OK_JSON")
  end

  # Also test with mixed case to ensure downcase is applied
  def test_load_adapter_from_string_name_downcases_mixed_case
    assert_equal "adapters/json_gem", capture_require_relative_path("Json_Gem")
  end

  def test_load_adapter_from_string_name_normalizes_case
    result = @instance.send(:load_adapter_from_string_name, "OK_JSON")

    assert_equal MultiJson::Adapters::OkJson, result
  end

  # Verify the class name is capitalized correctly from underscore-separated name
  def test_load_adapter_from_string_name_capitalizes_class_name
    result = @instance.send(:load_adapter_from_string_name, "ok_json")

    assert_equal "OkJson", result.name.split("::").last
  end

  # Verify loading works with various case combinations
  def test_load_adapter_from_string_name_handles_mixed_case
    result = @instance.send(:load_adapter_from_string_name, "JSON_GEM")

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  private

  def capture_require_relative_path(adapter_name)
    captured_path = nil
    test_module = create_path_capturing_module(->(path) { captured_path = path })
    Object.new.extend(test_module).send(:load_adapter_from_string_name, adapter_name)
    captured_path
  end

  def create_path_capturing_module(callback)
    ::Module.new do
      include MultiJson::AdapterSelector

      define_method(:require_relative) do |path|
        callback.call(path)
        ::Kernel.require(File.expand_path("../../lib/multi_json/#{path}", __dir__))
      end
    end
  end
end
