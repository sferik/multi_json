require_relative "../../test_helper"
require_relative "adapter_selection_test"

class InstanceAdapterSelectionIntegrationTest < Minitest::Test
  cover "MultiJson*"

  include IntegrationTestSetup

  def test_instance_adapter_loads_default_when_not_set
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }

    calls = []
    result = nil

    with_stub(object, :use, ->(value) { calls << value }, call_original: true) do
      result = object.send(:adapter)
    end

    assert_kind_of Module, result

    assert_equal [nil], calls
  end

  def test_instance_adapter_reloads_when_defined_as_nil
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }
    object.instance_variable_set(:@adapter, nil)

    calls = []
    result = nil

    with_stub(object, :use, ->(value) { calls << value }, call_original: true) do
      result = object.send(:adapter)
    end

    assert_kind_of Module, result

    assert_equal [nil], calls
  end

  def test_instance_adapter_returns_existing_without_reloading
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }
    object.send(:use, :json_gem)

    calls = []
    result = nil

    with_stub(object, :use, ->(value) { calls << value }, call_original: true) do
      result = object.send(:adapter)
    end

    assert_equal MultiJson::Adapters::JsonGem, result

    assert_empty calls
  end

  def test_instance_adapter_returns_fiber_local_override
    object = Class.new { include MultiJson }.new
    object.instance_variable_set(:@adapter, MultiJson::Adapters::JsonGem)
    stub_override = Object.new
    begin
      Fiber[:multi_json_adapter] = stub_override

      assert_same stub_override, object.send(:adapter)
    ensure
      Fiber[:multi_json_adapter] = nil
    end
  end

  def test_instance_adapter_ignores_nil_fiber_local
    object = Class.new { include MultiJson }.new
    object.instance_variable_set(:@adapter, MultiJson::Adapters::JsonGem)
    Fiber[:multi_json_adapter] = nil

    assert_equal MultiJson::Adapters::JsonGem, object.send(:adapter)
  end

  def test_gives_access_to_original_error_when_raising_adapter_error
    exception = get_exception(MultiJson::AdapterError) { MultiJson.use "foobar" }

    assert_instance_of LoadError, exception.cause
    assert_match %r{adapters/foobar}, exception.message
    assert_includes exception.message, "Did not recognize your adapter specification"
  end

  def test_can_set_adapter_for_block
    MultiJson.with_adapter(:json_gem) do
      MultiJson.with_engine(:json_gem) do
        assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
      end

      assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::Oj, MultiJson.adapter
  end

  def test_restores_adapter_after_exception
    MultiJson.use :json_gem
    original_adapter = MultiJson.adapter

    assert_raises(StandardError) { MultiJson.with_adapter(:oj) { raise StandardError } }

    assert_equal original_adapter, MultiJson.adapter
  end
end
