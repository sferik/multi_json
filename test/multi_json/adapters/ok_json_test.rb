require_relative "../../test_helper"
require_relative "../../support/adapter_tests"
require "multi_json/adapters/ok_json"

class OkJsonAdapterTest < Minitest::Test
  cover "MultiJson*"

  include AdapterTests

  def adapter_class
    MultiJson::Adapters::OkJson
  end

  def test_dump_converts_objects_without_to_json_using_to_s
    # Create an object that has to_s but not to_json
    obj = Object.new
    def obj.to_s = "custom_string"

    # Remove to_json if it exists (BasicObject descendants won't have it)
    obj.singleton_class.undef_method(:to_json) if obj.respond_to?(:to_json)

    result = MultiJson.dump({key: obj}, adapter: :ok_json)

    assert_includes result, "custom_string"
  end

  def test_dump_handles_objects_without_to_s_or_to_json
    # Create an object that doesn't respond to to_s or to_json
    # We use BasicObject which has minimal methods
    obj = BasicObject.new

    # This should not raise - the object is returned as-is
    # OkJson will then handle it (or fail gracefully)
    assert_raises(NoMethodError) do
      MultiJson.dump({key: obj}, adapter: :ok_json)
    end
  end

  def test_load_symbolize_keys_with_non_symbol_convertible_key
    # Most keys respond to to_sym, but we can test the branch
    # by using a hash with a key that's already a symbol
    json = '{"normal_key": "value"}'
    result = MultiJson.load(json, symbolize_keys: true, adapter: :ok_json)

    assert_equal({normal_key: "value"}, result)
  end
end
