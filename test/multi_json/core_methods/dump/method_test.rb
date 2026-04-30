# frozen_string_literal: true

require_relative "../../../test_helper"

class DumpMethodTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_dump_without_options_uses_empty_hash
    result = MultiJSON.dump({key: "value"})

    assert_equal '{"key":"value"}', result
  end

  def test_dump_with_options_passes_them_to_adapter
    result = MultiJSON.dump({a: 1, b: 2})

    assert_includes result, "a"
    assert_includes result, "b"
  end

  def test_dump_with_adapter_option_uses_specified_adapter
    MultiJSON.use :json_gem
    result = MultiJSON.dump({key: "value"}, adapter: :json_gem)

    assert_includes result, "key"
    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_dump_passes_options_to_current_adapter
    MultiJSON.use :json_gem
    result = MultiJSON.dump({test_key: "test_value"}, {})

    assert_includes result, "test_key"
  end

  def test_dump_options_default_is_empty_hash_not_nil
    MultiJSON.use :json_gem
    result = MultiJSON.dump([1, 2, 3])

    assert_equal "[1,2,3]", result
  end

  def test_dump_uses_current_adapter_for_encoding
    MultiJSON.use :json_gem
    result = MultiJSON.dump({a: 1})

    assert_includes result, "a"
  end

  def test_dump_passes_object_to_adapter_dump
    MultiJSON.use :json_gem
    result = MultiJSON.dump({key: "value"})

    assert_includes result, "key"
    assert_includes result, "value"
  end

  def test_dump_returns_json_string
    result = MultiJSON.dump({test: 123})

    assert_kind_of String, result
  end
end
