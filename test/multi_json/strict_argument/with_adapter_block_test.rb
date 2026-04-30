# frozen_string_literal: true

require_relative "../../test_helper"

class WithAdapterBlockExecutionTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_with_adapter_returns_block_result
    result = MultiJSON.with_adapter(:json_gem) { "block_result" }

    assert_equal "block_result", result
  end

  def test_with_adapter_executes_block
    executed = false

    MultiJSON.with_adapter(:json_gem) { executed = true }

    assert executed
  end

  def test_with_adapter_changes_adapter_inside_block
    inner_adapter = nil

    MultiJSON.with_adapter(:json_gem) do
      inner_adapter = MultiJSON.adapter
    end

    assert_equal MultiJSON::Adapters::JsonGem, inner_adapter
  end

  def test_with_adapter_captures_original_adapter
    MultiJSON.use :json_gem
    original = MultiJSON.adapter

    MultiJSON.with_adapter(:json_gem) { nil }

    assert_equal original, MultiJSON.adapter
  end

  def test_with_adapter_restores_on_exception
    MultiJSON.use :json_gem

    assert_raises(RuntimeError) do
      MultiJSON.with_adapter(:json_gem) { raise "error" }
    end

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_with_adapter_restores_exact_adapter
    MultiJSON.use :json_gem
    expected = MultiJSON.adapter

    MultiJSON.with_adapter(:json_gem) { nil }

    assert_same expected, MultiJSON.adapter
  end

  def test_with_adapter_uses_argument
    skip unless defined?(::Oj)
    MultiJSON.use :json_gem

    MultiJSON.with_adapter(:oj) do
      refute_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
      assert_equal MultiJSON::Adapters::Oj, MultiJSON.adapter
    end
  end
end
