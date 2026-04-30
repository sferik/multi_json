# frozen_string_literal: true

require_relative "../../test_helper"

# Shared setup for integration tests requiring Oj adapter
module IntegrationTestSetup
  def setup
    skip "java based implementations" if TestHelpers.java?
    MultiJSON.use :oj
    return unless MultiJSON.instance_variable_defined?(:@default_adapter)

    MultiJSON.remove_instance_variable(:@default_adapter)
  end
end

class AdapterSelectionIntegrationTest < Minitest::Test
  cover "MultiJSON*"

  include IntegrationTestSetup

  def test_defaults_to_best_available_gem
    MultiJSON.send(:remove_instance_variable, :@adapter) if MultiJSON.instance_variable_defined?(:@adapter)

    assert_equal expected_default_adapter, MultiJSON.adapter.to_s
  end

  def test_adapter_loads_default_when_not_set
    original = MultiJSON.adapter
    clear_adapter_state
    calls = []
    result = with_use_calls(calls) { MultiJSON.adapter }

    assert_kind_of Module, result
    assert_equal [nil], calls
  ensure
    MultiJSON.use original
  end

  def test_adapter_reloads_when_adapter_is_defined_as_nil
    original = MultiJSON.adapter
    MultiJSON.instance_variable_set(:@adapter, nil)

    calls = []
    result = with_use_calls(calls) { MultiJSON.adapter }

    assert_kind_of Module, result
    assert_equal [nil], calls
  ensure
    MultiJSON.use original
  end

  def test_adapter_does_not_define_adapter_when_load_fails
    original = MultiJSON.adapter
    clear_adapter_state

    assert_raises(StandardError) do
      with_stub(MultiJSON, :use, ->(*) { raise StandardError, "boom" }) { MultiJSON.adapter }
    end

    refute MultiJSON.instance_variable_defined?(:@adapter)
  ensure
    MultiJSON.use original
  end

  def test_adapter_handles_nil_result_without_recursion
    original = MultiJSON.adapter
    result, use_calls = adapter_result_with_nil_recursion

    assert_nil result
    assert_equal 1, use_calls
  ensure
    MultiJSON.use original
  end

  def test_adapter_returns_existing_without_reloading
    original = MultiJSON.adapter
    MultiJSON.use :json_gem

    calls = []
    result = with_use_calls(calls) { MultiJSON.adapter }

    assert_equal MultiJSON::Adapters::JsonGem, result
    assert_empty calls
  ensure
    MultiJSON.use original
  end

  def test_looks_for_adapter_even_if_adapter_variable_is_nil
    MultiJSON.send(:remove_instance_variable, :@adapter) if MultiJSON.instance_variable_defined?(:@adapter)

    result = with_stub(MultiJSON, :default_adapter, -> { :json_gem }) { MultiJSON.adapter }

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  private

  def clear_adapter_state
    MultiJSON.send(:remove_instance_variable, :@adapter) if MultiJSON.instance_variable_defined?(:@adapter)
    MultiJSON.send(:remove_instance_variable, :@default_adapter) if MultiJSON.instance_variable_defined?(:@default_adapter)
  end

  def with_use_calls(calls, &block)
    result = nil
    with_stub(MultiJSON, :use, ->(value) { calls << value }, call_original: true) { result = block.call }
    result
  end

  def adapter_result_with_nil_recursion
    clear_adapter_state
    use_calls = 0
    result = nil
    stub = lambda do |*|
      use_calls += 1
      MultiJSON.instance_variable_set(:@adapter, nil)
    end

    with_stub(MultiJSON, :use, stub) { result = MultiJSON.adapter }

    [result, use_calls]
  end
end
