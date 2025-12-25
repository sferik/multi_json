require_relative "../../test_helper"

class AdapterMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_adapter_returns_current_adapter_class
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_adapter_loads_default_when_not_set
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)
    # Ensure default_adapter is set to a known available adapter
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    refute_nil MultiJson.adapter
  ensure
    MultiJson.use :json_gem
  end

  def test_adapter_returns_same_instance_on_repeated_calls
    adapter1 = MultiJson.adapter
    adapter2 = MultiJson.adapter

    assert_same adapter1, adapter2
  end

  def test_adapter_returns_adapter_when_defined_and_truthy
    # Tests that the condition checks both defined? and truthiness
    MultiJson.use :ok_json

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_adapter_short_circuits_when_already_set
    # If adapter is already set, it should return immediately without calling use(nil)
    MultiJson.use :json_gem
    use_called = false
    original_use = MultiJson.method(:use)
    silence_warnings do
      MultiJson.define_singleton_method(:use) { |arg| (use_called = true if arg.nil?) || original_use.call(arg) }
    end
    MultiJson.adapter

    refute use_called
  ensure
    silence_warnings { MultiJson.define_singleton_method(:use, original_use) } if original_use
  end

  def test_adapter_returns_the_adapter_instance_not_nil
    MultiJson.use :ok_json

    result = MultiJson.adapter

    assert_equal MultiJson::Adapters::OkJson, result
    refute_nil result
  end

  def test_adapter_returns_correct_adapter_class_after_change
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter

    MultiJson.use :ok_json

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end
end

# Tests for adapter method behavior when undefined
class AdapterUndefinedTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_adapter_when_undefined_calls_use_nil
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)

    use_nil_called = with_stub(MultiJson, :default_adapter, -> { :json_gem }) do
      with_use_tracking { |called| capture_stderr { MultiJson.adapter } && called[:nil] }
    end

    assert use_nil_called, "use(nil) should be called when @adapter is undefined"
  end

  def test_adapter_checks_both_defined_and_truthiness
    MultiJson.instance_variable_set(:@adapter, nil)

    use_nil_called = with_use_tracking { |called| capture_stderr { MultiJson.adapter } && called[:nil] }

    assert use_nil_called, "use(nil) should be called when @adapter is nil"
  ensure
    MultiJson.use :json_gem
  end

  def test_adapter_returns_valid_adapter_when_ivar_is_nil
    MultiJson.instance_variable_set(:@adapter, nil)

    result = with_stub(MultiJson, :default_adapter, -> { :json_gem }) do
      capture_stderr { MultiJson.adapter }
    end

    refute_nil result, "adapter should not return nil when @adapter is nil"
    assert_kind_of Module, result
  ensure
    MultiJson.use :json_gem
  end

  def test_adapter_with_nil_ivar_loads_default
    MultiJson.instance_variable_set(:@adapter, nil)
    MultiJson.instance_variable_set(:@default_adapter, :ok_json)

    result = capture_stderr { MultiJson.adapter }

    assert_equal MultiJson::Adapters::OkJson, result
  ensure
    MultiJson.use :json_gem
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end

  def test_adapter_method_returns_value_from_instance_variable
    MultiJson.use :ok_json
    expected = MultiJson.instance_variable_get(:@adapter)

    result = MultiJson.adapter

    assert_same expected, result
  end

  private

  def with_use_tracking
    called = {nil: false}
    stub = ->(arg) { called[:nil] = true if arg.nil? }
    with_stub(MultiJson, :use, stub, call_original: true) { yield called }
  end
end
