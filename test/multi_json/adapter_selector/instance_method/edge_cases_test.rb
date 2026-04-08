require_relative "../../../test_helper"
require "multi_json/adapter_selector"

# Additional tests for instance method edge cases and error handling
class IncludedAdapterSelectorEdgeCasesTest < Minitest::Test
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
    assert_includes MultiJson::AdapterSelector::REQUIREMENT_MAP.keys, result
  end

  def test_instance_load_adapter_by_name_with_symbol
    assert_equal MultiJson::Adapters::JsonGem, @instance.send(:load_adapter_by_name, "json_gem")
  end

  def test_instance_load_adapter_by_name_uses_aliases
    skip "JrJackson not available" unless TestHelpers.jrjackson?

    assert_equal MultiJson::Adapters::JrJackson, @instance.send(:load_adapter_by_name, "jrjackson")
  end

  def test_instance_load_adapter_by_name_downcases
    assert_equal MultiJson::Adapters::JsonGem, @instance.send(:load_adapter_by_name, "JSON_GEM")
  end

  def test_instance_load_adapter_by_name_uses_multijson_adapters
    result = @instance.send(:load_adapter_by_name, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
    assert_equal "MultiJson::Adapters::JsonGem", result.name
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

  def test_instance_load_adapter_error_includes_adapter_value
    error = assert_raises(MultiJson::AdapterError) { @instance.send(:load_adapter, 99_999) }

    assert_kind_of LoadError, error.cause
    assert_includes error.cause.message, "99999"
  end

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
    assert_equal MultiJson::Adapters::JsonGem, @instance.send(:load_adapter_by_name, "JSON_GEM")
  end

  def test_instance_loaded_adapter_explicit_nil_return
    simulate_no_adapters { assert_nil @instance.send(:loaded_adapter) }
  end

  def test_instance_load_adapter_error_is_built_from_exception
    error = assert_raises(MultiJson::AdapterError) { @instance.send(:load_adapter, :nonexistent_adapter) }

    assert_includes error.message, "Did not recognize", "Error message should come from build()"
  end
end
