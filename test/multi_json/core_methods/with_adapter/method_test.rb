# frozen_string_literal: true

require_relative "../../../test_helper"

class WithAdapterMethodTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_with_adapter_temporarily_changes_adapter
    MultiJSON.use :json_gem
    inner_adapter = nil

    MultiJSON.with_adapter(:json_gem) do
      inner_adapter = MultiJSON.adapter
    end

    assert_equal MultiJSON::Adapters::JsonGem, inner_adapter
  end

  def test_with_adapter_restores_original_adapter
    MultiJSON.use :json_gem

    MultiJSON.with_adapter(:json_gem) { nil }

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_with_adapter_restores_adapter_on_exception
    MultiJSON.use :json_gem

    assert_raises(RuntimeError) do
      MultiJSON.with_adapter(:json_gem) { raise "test error" }
    end

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_with_adapter_returns_block_value
    result = MultiJSON.with_adapter(:json_gem) { "block result" }

    assert_equal "block result", result
  end

  def test_with_adapter_captures_adapter_before_block
    MultiJSON.use :json_gem
    original = MultiJSON.adapter

    MultiJSON.with_adapter(:json_gem) { nil }

    assert_same original, MultiJSON.adapter
  end

  def test_with_adapter_executes_block
    executed = false
    MultiJSON.with_adapter(:json_gem) { executed = true }

    assert executed
  end

  def test_with_adapter_changes_adapter_inside_block
    MultiJSON.use :json_gem

    MultiJSON.with_adapter(:json_gem) do
      assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
    end
  end

  def test_with_adapter_restores_different_adapter
    MultiJSON.use :json_gem
    MultiJSON.with_adapter(:json_gem) { nil }

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_with_adapter_nested_restores_correctly
    MultiJSON.use :json_gem

    MultiJSON.with_adapter(:json_gem) do
      MultiJSON.with_adapter(:json_gem) do
        assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
      end
      assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
    end

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_with_adapter_nil_uses_default_parse_and_generate_adapters
    MultiJSON.use :oj

    MultiJSON.with_adapter(nil) do
      assert_equal MultiJSON.send(:load_adapter, MultiJSON.default_parse_adapter), MultiJSON.parse_adapter
      assert_equal MultiJSON.send(:load_adapter, MultiJSON.default_generate_adapter), MultiJSON.generate_adapter
    end
  end

  def test_with_adapter_directional_nil_resets_one_side_to_default
    MultiJSON.use :oj

    MultiJSON.with_adapter(parse: nil) do
      assert_equal MultiJSON.send(:load_adapter, MultiJSON.default_parse_adapter), MultiJSON.parse_adapter
      assert_equal MultiJSON::Adapters::Oj, MultiJSON.generate_adapter
    end
  end
end
