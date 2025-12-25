require_relative "../../test_helper"

# Load all available adapters
MultiJson::REQUIREMENT_MAP.each_value do |library|
  require library
rescue LoadError
  next
end

# Shared setup for integration tests requiring Oj adapter
module IntegrationTestSetup
  def setup
    skip "java based implementations" if TestHelpers.java?
    MultiJson.use :oj
    return unless MultiJson.instance_variable_defined?(:@default_adapter)

    MultiJson.remove_instance_variable(:@default_adapter)
  end
end

class AdapterSelectionIntegrationTest < Minitest::Test
  cover "MultiJson*"

  include IntegrationTestSetup

  def test_defaults_to_best_available_gem
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)

    assert_equal expected_default_adapter, MultiJson.adapter.to_s
  end

  def test_adapter_loads_default_when_not_set
    original = MultiJson.adapter
    clear_adapter_state
    calls = []
    result = with_use_calls(calls) { MultiJson.adapter }

    assert_kind_of Module, result
    assert_equal [nil], calls
  ensure
    MultiJson.use original
  end

  def test_adapter_reloads_when_adapter_is_defined_as_nil
    original = MultiJson.adapter
    MultiJson.instance_variable_set(:@adapter, nil)

    calls = []
    result = with_use_calls(calls) { MultiJson.adapter }

    assert_kind_of Module, result
    assert_equal [nil], calls
  ensure
    MultiJson.use original
  end

  def test_adapter_does_not_define_adapter_when_load_fails
    original = MultiJson.adapter
    clear_adapter_state

    assert_raises(StandardError) do
      with_stub(MultiJson, :use, ->(*) { raise StandardError, "boom" }) { MultiJson.adapter }
    end

    refute MultiJson.instance_variable_defined?(:@adapter)
  ensure
    MultiJson.use original
  end

  def test_adapter_handles_nil_result_without_recursion
    original = MultiJson.adapter
    result, use_calls = adapter_result_with_nil_recursion

    assert_nil result
    assert_equal 1, use_calls
  ensure
    MultiJson.use original
  end

  def test_adapter_returns_existing_without_reloading
    original = MultiJson.adapter
    MultiJson.use :json_gem

    calls = []
    result = with_use_calls(calls) { MultiJson.adapter }

    assert_equal MultiJson::Adapters::JsonGem, result
    assert_empty calls
  ensure
    MultiJson.use original
  end

  def test_looks_for_adapter_even_if_adapter_variable_is_nil
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)

    result = with_stub(MultiJson, :default_adapter, -> { :ok_json }) { MultiJson.adapter }

    assert_equal MultiJson::Adapters::OkJson, result
  end

  private

  def clear_adapter_state
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)
    MultiJson.send(:remove_instance_variable, :@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end

  def with_use_calls(calls, &block)
    result = nil
    with_stub(MultiJson, :use, ->(value) { calls << value }, call_original: true) { result = block.call }
    result
  end

  def adapter_result_with_nil_recursion
    clear_adapter_state
    use_calls = 0
    result = nil
    stub = lambda do |*|
      use_calls += 1
      MultiJson.instance_variable_set(:@adapter, nil)
    end

    with_stub(MultiJson, :use, stub) { result = MultiJson.adapter }

    [result, use_calls]
  end
end
