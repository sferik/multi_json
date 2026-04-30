# frozen_string_literal: true

require_relative "../../../test_helper"
require_relative "dump_test"

class InstanceMethodLoadTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    @object = create_multi_json_object
    MultiJSON.use :json_gem
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_instance_parse_returns_parsed_data
    result = @object.send(:parse, '{"key":"value"}')

    assert_equal({"key" => "value"}, result)
  end

  def test_instance_parse_with_options
    result = @object.send(:parse, '{"a":1}', symbolize_names: true)

    assert_equal({a: 1}, result)
  end

  def test_instance_parse_calls_adapter_load
    result = @object.send(:parse, '{"test":123}')

    assert_equal 123, result["test"]
  end

  def test_instance_parse_respects_adapter_option
    result = @object.send(:parse, '{"x":1}', adapter: :json_gem)

    assert_equal({"x" => 1}, result)
  end

  def test_instance_parse_raises_parse_error
    error = assert_raises(MultiJSON::ParseError) do
      @object.send(:parse, "{bad}")
    end

    assert_kind_of MultiJSON::ParseError, error
  end

  def test_instance_parse_error_has_data
    error = assert_raises(MultiJSON::ParseError) do
      @object.send(:parse, "{test_data}")
    end

    assert_equal "{test_data}", error.data
    refute_nil error.data
  end

  def test_instance_parse_error_has_cause
    error = assert_raises(MultiJSON::ParseError) do
      @object.send(:parse, "{broken}")
    end

    refute_nil error.cause
    assert_kind_of Exception, error.cause
  end

  def test_instance_parse_passes_options_to_adapter_load
    @object.send(:use, :json_gem)
    result = @object.send(:parse, '{"key":"value"}', symbolize_names: true)

    assert_equal({key: "value"}, result)
  end

  def test_instance_parse_uses_passed_options_not_empty
    @object.send(:use, :json_gem)
    result = @object.send(:parse, '{"a":"b"}', symbolize_names: true)

    assert result.key?(:a)
    refute result.key?("a")
  end

  def test_instance_parse_passes_options_to_current_adapter
    @object.send(:use, TestHelpers::StrictAdapter)
    TestHelpers::StrictAdapter.reset_calls

    @object.send(:parse, '{"x":1}', adapter: :json_gem)

    assert_empty TestHelpers::StrictAdapter.load_calls, "StrictAdapter should NOT be called with adapter: :json_gem"
  end

  def test_instance_parse_uses_adapter_from_options
    @object.send(:use, :json_gem)
    result = @object.send(:parse, '{"test":true}', adapter: :json_gem)

    assert_equal({"test" => true}, result)
  end

  def test_instance_parse_without_options_passes_empty_hash_not_nil
    @object.send(:use, TestHelpers::StrictAdapter)
    TestHelpers::StrictAdapter.reset_calls

    # StrictAdapter raises ArgumentError if options is nil
    # This test ensures the default parameter is {} not nil
    @object.send(:parse, '{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_kind_of Hash, call[:options]
  end

  private

  def create_multi_json_object
    obj = InstanceMethodDumpTest::MultiJsonTestObject.new
    obj.send(:use, :json_gem)
    obj
  end
end
