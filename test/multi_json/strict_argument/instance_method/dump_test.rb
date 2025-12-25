require_relative "../../../test_helper"

# Tests that use instance methods (via include MultiJson)
class InstanceMethodDumpTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_dump_returns_json_string
    result = @object.send(:dump, {key: "value"})

    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_instance_dump_with_options
    result = @object.send(:dump, {a: 1}, {})

    assert_kind_of String, result
  end

  def test_instance_dump_calls_adapter_dump
    result = @object.send(:dump, {test: 123})

    assert_includes result, "test"
    assert_includes result, "123"
  end

  def test_instance_dump_respects_adapter_option
    result = @object.send(:dump, {x: 1}, adapter: :ok_json)

    assert_kind_of String, result
  end

  def test_instance_dump_passes_options_to_adapter_dump
    @object.send(:use, :json_gem)
    result = @object.send(:dump, {a: 1}, pretty: true)

    assert_includes result, "\n", "Pretty option should add newlines"
  end

  def test_instance_dump_uses_passed_options_not_empty
    @object.send(:use, :json_gem)
    result = @object.send(:dump, {a: 1}, pretty: true, indent: "  ")

    assert_includes result, "\n"
  end

  def test_instance_dump_passes_options_to_current_adapter
    @object.send(:use, TestHelpers::StrictAdapter)
    TestHelpers::StrictAdapter.reset_calls

    @object.send(:dump, {x: 1}, adapter: :json_gem)

    assert_empty TestHelpers::StrictAdapter.dump_calls, "StrictAdapter should NOT be called with adapter: :json_gem"
  end

  private

  def create_multi_json_object
    obj = MultiJsonTestObject.new
    obj.send(:use, :json_gem)
    obj
  end

  class MultiJsonTestObject
    include MultiJson

    def load_adapter(val)
      MultiJson.send(:load_adapter, val)
    end
  end
end
