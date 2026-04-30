# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests that use instance methods (via include MultiJSON)
class InstanceMethodDumpTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    @object = create_multi_json_object
    MultiJSON.use :json_gem
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_instance_generate_returns_json_string
    result = @object.send(:generate, {key: "value"})

    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_instance_generate_with_options
    result = @object.send(:generate, {a: 1}, {})

    assert_kind_of String, result
  end

  def test_instance_generate_calls_adapter_dump
    result = @object.send(:generate, {test: 123})

    assert_includes result, "test"
    assert_includes result, "123"
  end

  def test_instance_generate_respects_adapter_option
    result = @object.send(:generate, {x: 1}, adapter: :json_gem)

    assert_kind_of String, result
  end

  def test_instance_generate_passes_options_to_adapter_dump
    @object.send(:use, :json_gem)
    result = @object.send(:generate, {a: 1}, pretty: true)

    assert_includes result, "\n", "Pretty option should add newlines"
  end

  def test_instance_generate_uses_passed_options_not_empty
    @object.send(:use, :json_gem)
    result = @object.send(:generate, {a: 1}, pretty: true, indent: "  ")

    assert_includes result, "\n"
  end

  def test_instance_generate_passes_options_to_current_adapter
    @object.send(:use, TestHelpers::StrictAdapter)
    TestHelpers::StrictAdapter.reset_calls

    @object.send(:generate, {x: 1}, adapter: :json_gem)

    assert_empty TestHelpers::StrictAdapter.dump_calls, "StrictAdapter should NOT be called with adapter: :json_gem"
  end

  def test_instance_generate_without_options_passes_empty_hash_not_nil
    @object.send(:use, TestHelpers::StrictAdapter)
    TestHelpers::StrictAdapter.reset_calls

    # StrictAdapter raises ArgumentError if options is nil
    # This test ensures the default parameter is {} not nil
    @object.send(:generate, {a: 1})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_kind_of Hash, call[:options]
  end

  private

  def create_multi_json_object
    obj = MultiJsonTestObject.new
    obj.send(:use, :json_gem)
    obj
  end

  class MultiJsonTestObject
    include MultiJSON

    def load_adapter(val)
      MultiJSON.send(:load_adapter, val)
    end
  end
end
