# frozen_string_literal: true

require_relative "../../test_helper"

class AdapterMethodTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_adapter_returns_current_adapter_class
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_adapter_loads_default_when_not_set
    MultiJSON.send(:remove_instance_variable, :@parse_adapter) if MultiJSON.instance_variable_defined?(:@parse_adapter)
    MultiJSON.instance_variable_set(:@default_parse_adapter, :json_gem)

    refute_nil MultiJSON.adapter
  ensure
    MultiJSON.use :json_gem
  end

  def test_adapter_returns_same_instance_on_repeated_calls
    adapter1 = MultiJSON.adapter
    adapter2 = MultiJSON.adapter

    assert_same adapter1, adapter2
  end

  def test_adapter_returns_adapter_when_defined_and_truthy
    # Tests that the condition checks both defined? and truthiness
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_adapter_short_circuits_when_already_set
    # If adapter is already set, it should return immediately without reloading defaults.
    MultiJSON.use :json_gem
    load_called = false
    original_load_adapter = MultiJSON.method(:load_adapter)
    silence_warnings do
      MultiJSON.define_singleton_method(:load_adapter) { |arg| (load_called = true if arg == :json_gem) || original_load_adapter.call(arg) }
    end
    MultiJSON.adapter

    refute load_called
  ensure
    silence_warnings { MultiJSON.define_singleton_method(:load_adapter, original_load_adapter) } if original_load_adapter
  end

  def test_adapter_returns_the_adapter_instance_not_nil
    MultiJSON.use :json_gem

    result = MultiJSON.adapter

    assert_equal MultiJSON::Adapters::JsonGem, result
    refute_nil result
  end

  def test_adapter_returns_correct_adapter_class_after_change
    skip unless defined?(::Oj)
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter

    MultiJSON.use :oj

    assert_equal MultiJSON::Adapters::Oj, MultiJSON.adapter
  end
end

# Tests for adapter method behavior when undefined
class AdapterUndefinedTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_adapter_when_undefined_calls_use_nil
    MultiJSON.send(:remove_instance_variable, :@parse_adapter) if MultiJSON.instance_variable_defined?(:@parse_adapter)

    load_called = with_stub(MultiJSON, :default_parse_adapter, -> { :json_gem }) do
      with_load_tracking { |called| capture_stderr { MultiJSON.adapter } && called[:json_gem] }
    end

    assert load_called, "load_adapter should be called when @parse_adapter is undefined"
  end

  def test_adapter_checks_both_defined_and_truthiness
    MultiJSON.instance_variable_set(:@parse_adapter, nil)

    load_called = with_stub(MultiJSON, :default_parse_adapter, -> { :json_gem }) do
      with_load_tracking { |called| capture_stderr { MultiJSON.adapter } && called[:json_gem] }
    end

    assert load_called, "load_adapter should be called when @parse_adapter is nil"
  ensure
    MultiJSON.use :json_gem
  end

  def test_adapter_returns_valid_adapter_when_ivar_is_nil
    MultiJSON.instance_variable_set(:@parse_adapter, nil)

    result = with_stub(MultiJSON, :default_parse_adapter, -> { :json_gem }) do
      capture_stderr { MultiJSON.adapter }
    end

    refute_nil result, "adapter should not return nil when @adapter is nil"
    assert_kind_of Module, result
  ensure
    MultiJSON.use :json_gem
  end

  def test_adapter_with_nil_ivar_loads_default
    MultiJSON.instance_variable_set(:@parse_adapter, nil)
    MultiJSON.instance_variable_set(:@default_parse_adapter, :json_gem)

    result = capture_stderr { MultiJSON.adapter }

    assert_equal MultiJSON::Adapters::JsonGem, result
  ensure
    MultiJSON.use :json_gem
    MultiJSON.remove_instance_variable(:@default_parse_adapter) if MultiJSON.instance_variable_defined?(:@default_parse_adapter)
  end

  def test_adapter_method_returns_value_from_instance_variable
    MultiJSON.use :json_gem
    expected = MultiJSON.instance_variable_get(:@parse_adapter)

    result = MultiJSON.adapter

    assert_same expected, result
  end

  private

  def with_load_tracking
    called = {json_gem: false}
    stub = ->(arg) { called[:json_gem] = true if arg == :json_gem }
    with_stub(MultiJSON, :load_adapter, stub, call_original: true) { yield called }
  end
end
