# frozen_string_literal: true

require_relative "../../../test_helper"
require "multi_json/adapter_selector"

# Tests adapter selector via instance methods (using include)
class IncludedAdapterSelectorTest < Minitest::Test
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

  def test_instance_default_adapter_returns_cached_when_defined
    @instance.instance_variable_set(:@default_adapter, :json_gem)

    result = @instance.default_adapter

    assert_equal :json_gem, result
  end

  def test_instance_default_adapter_computes_when_not_defined
    @instance.remove_instance_variable(:@default_adapter) if @instance.instance_variable_defined?(:@default_adapter)

    result = capture_stderr { @instance.default_adapter }

    refute_nil result
    assert_kind_of Symbol, result
  end

  def test_instance_default_adapter_caches_computed_value
    @instance.remove_instance_variable(:@default_adapter) if @instance.instance_variable_defined?(:@default_adapter)

    capture_stderr { @instance.default_adapter }

    assert @instance.instance_variable_defined?(:@default_adapter)
  end

  def test_instance_default_adapter_falls_back_to_installable
    simulate_no_adapters do
      @instance.remove_instance_variable(:@default_adapter) if @instance.instance_variable_defined?(:@default_adapter)

      result = capture_stderr { @instance.default_adapter }

      assert_equal :json_gem, result
    end
  end

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
