# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/adapter_selector"

# Tests that absolute namespace references work correctly with conflicting constants
class AbsoluteNamespaceReferenceTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  def teardown
    remove_conflicting_constants
  end

  def test_installable_adapter_resolves_requirement_map_to_canonical_constant
    # Now that REQUIREMENT_MAP lives on AdapterSelector itself, the bare
    # constant lookup IS the canonical reference. Confirm a fresh include
    # picks up the canonical map.
    result = @instance.send(:installable_adapter)

    refute_nil result, "installable_adapter should resolve REQUIREMENT_MAP from AdapterSelector"
    assert_includes MultiJson::AdapterSelector::REQUIREMENT_MAP.keys, result
  end

  def test_load_adapter_by_name_uses_absolute_namespace_for_adapters
    define_conflicting_adapters

    result = @instance.send(:load_adapter_by_name, "json_gem")

    assert_equal ::MultiJson::Adapters::JsonGem, result
    assert_equal "MultiJson::Adapters::JsonGem", result.name
  end

  def test_load_adapter_by_name_uses_absolute_not_relative_multijson
    define_nested_multijson_with_adapters

    result = @instance.send(:load_adapter_by_name, "json_gem")

    assert_equal ::MultiJson::Adapters::JsonGem, result
    assert_equal "MultiJson::Adapters::JsonGem", result.name
  end

  private

  def define_conflicting_adapters
    return if MultiJson::AdapterSelector.const_defined?(:Adapters, false)

    fake_adapters = Module.new do
      def self.const_get(_name)
        Module.new
      end
    end
    MultiJson::AdapterSelector.const_set(:Adapters, fake_adapters)
  end

  def define_nested_multijson_with_adapters
    return if MultiJson::AdapterSelector.const_defined?(:MultiJson, false)

    fake_adapters = Module.new do
      def self.const_get(_name)
        Module.new
      end
    end
    nested = Module.new
    nested.const_set(:Adapters, fake_adapters)
    MultiJson::AdapterSelector.const_set(:MultiJson, nested)
  end

  def remove_conflicting_constants
    remove_const_if_defined(:Adapters)
    remove_const_if_defined(:MultiJson)
  end

  def remove_const_if_defined(const_name)
    return unless MultiJson::AdapterSelector.const_defined?(const_name, false)

    MultiJson::AdapterSelector.send(:remove_const, const_name)
  end
end

# Tests that module type checking works correctly
class ModuleTypeCheckingTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def setup
    @test_class = Class.new { include MultiJson::AdapterSelector }
    @instance = @test_class.new
  end

  def test_load_adapter_handles_class_via_is_a_module
    custom_class = valid_custom_class

    result = @instance.send(:load_adapter, custom_class)

    assert_equal custom_class, result
  end

  def test_load_adapter_uses_absolute_module_reference
    fake_module = Object.new.tap do |fake|
      fake.define_singleton_method(:===) { |_| false }
      fake.define_singleton_method(:name) { "FakeModule" }
    end
    MultiJson::AdapterSelector.const_set(:Module, fake_module)

    custom_module = valid_custom_module
    result = @instance.send(:load_adapter, custom_module)

    assert_equal custom_module, result
  ensure
    MultiJson::AdapterSelector.send(:remove_const, :Module) if MultiJson::AdapterSelector.const_defined?(:Module, false)
  end

  def test_load_adapter_handles_module_instance
    custom_module = valid_custom_module

    result = @instance.send(:load_adapter, custom_module)

    assert_equal custom_module, result
  end

  def test_load_adapter_uses_absolute_string_reference
    fake_string = Object.new.tap do |fake|
      fake.define_singleton_method(:===) { |_| false }
      fake.define_singleton_method(:name) { "FakeString" }
    end
    MultiJson::AdapterSelector.const_set(:String, fake_string)

    result = @instance.send(:load_adapter, "json_gem")

    assert_equal MultiJson::Adapters::JsonGem, result
  ensure
    MultiJson::AdapterSelector.send(:remove_const, :String) if MultiJson::AdapterSelector.const_defined?(:String, false)
  end

  def test_load_adapter_uses_absolute_symbol_reference
    fake_symbol = Object.new.tap do |fake|
      fake.define_singleton_method(:===) { |_| false }
      fake.define_singleton_method(:name) { "FakeSymbol" }
    end
    MultiJson::AdapterSelector.const_set(:Symbol, fake_symbol)

    result = @instance.send(:load_adapter, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
  ensure
    MultiJson::AdapterSelector.send(:remove_const, :Symbol) if MultiJson::AdapterSelector.const_defined?(:Symbol, false)
  end

  private

  def valid_custom_class
    ::Class.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = "{}"
    end
  end

  def valid_custom_module
    ::Module.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.load(_string, _options) = nil
      def self.dump(_object, _options) = "{}"
    end
  end
end
