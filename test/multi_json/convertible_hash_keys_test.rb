require_relative "../test_helper"
require "multi_json/convertible_hash_keys"

class ConvertibleHashKeysTest < Minitest::Test
  cover "MultiJson::ConvertibleHashKeys*"

  # Test class that includes ConvertibleHashKeys to access private methods
  class KeyConverter
    include MultiJson::ConvertibleHashKeys

    public :symbolize_keys, :stringify_keys, :convert_simple_object
  end

  def setup
    @converter = KeyConverter.new
  end

  def test_symbolize_keys_with_key_not_responding_to_to_sym
    # Build a hash with a key that doesn't respond to to_sym - we need to test the branch directly
    # Since we can't easily create a hash with BasicObject keys through normal means,
    # we test by stubbing respond_to? on a regular object
    stubbed_key = Object.new
    stubbed_key.define_singleton_method(:respond_to?) { |method, *| method != :to_sym }

    hash = {stubbed_key => "value"}
    result = @converter.symbolize_keys(hash)

    # The key should be returned as-is since it doesn't respond to to_sym
    assert_equal stubbed_key, result.keys.first
  end

  def test_stringify_keys_with_key_not_responding_to_to_s
    # Create an object that doesn't respond to to_s
    stubbed_key = Object.new
    stubbed_key.define_singleton_method(:respond_to?) { |method, *| method != :to_s }

    hash = {stubbed_key => "value"}
    result = @converter.stringify_keys(hash)

    # The key should be returned as-is since it doesn't respond to to_s
    assert_equal stubbed_key, result.keys.first
  end

  def test_convert_simple_object_with_object_not_responding_to_to_s
    # Create an object that doesn't respond to to_s or to_json
    stubbed_obj = Object.new
    stubbed_obj.define_singleton_method(:respond_to?) { |_method, *| false }

    result = @converter.convert_simple_object(stubbed_obj)

    # The object should be returned as-is
    assert_same stubbed_obj, result
  end

  def test_symbolize_keys_with_nested_structures
    hash = {"outer" => {"inner" => "value"}, "array" => [{"nested" => "item"}]}
    result = @converter.symbolize_keys(hash)

    assert_equal({outer: {inner: "value"}, array: [{nested: "item"}]}, result)
  end

  def test_stringify_keys_with_nested_structures
    hash = {outer: {inner: "value"}, array: [{nested: "item"}]}
    result = @converter.stringify_keys(hash)

    assert_equal({"outer" => {"inner" => "value"}, "array" => [{"nested" => "item"}]}, result)
  end

  def test_convert_simple_object_returns_string_as_is
    assert_equal "string", @converter.convert_simple_object("string")
  end

  def test_convert_simple_object_returns_integer_as_is
    assert_equal 42, @converter.convert_simple_object(42)
  end

  def test_convert_simple_object_returns_float_as_is
    assert_in_delta(3.14, @converter.convert_simple_object(3.14))
  end

  def test_convert_simple_object_returns_boolean_as_is
    assert @converter.convert_simple_object(true)
    refute @converter.convert_simple_object(false)
  end

  def test_convert_simple_object_returns_nil_as_is
    assert_nil @converter.convert_simple_object(nil)
  end

  def test_convert_simple_object_returns_object_with_to_json_as_is
    obj = Object.new
    def obj.to_json = '{"custom":"json"}'

    result = @converter.convert_simple_object(obj)

    assert_same obj, result
  end

  def test_convert_simple_object_converts_using_to_s_when_no_to_json
    obj = Object.new
    obj.define_singleton_method(:respond_to?) do |method, *|
      method != :to_json && Object.instance_method(:respond_to?).bind_call(self, method)
    end
    def obj.to_s = "converted_string"

    result = @converter.convert_simple_object(obj)

    assert_equal "converted_string", result
  end
end
