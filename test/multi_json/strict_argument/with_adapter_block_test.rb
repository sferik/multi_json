# frozen_string_literal: true

require_relative "../../test_helper"

class WithAdapterBlockExecutionTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_with_adapter_returns_block_result
    result = MultiJson.with_adapter(:json_gem) { "block_result" }

    assert_equal "block_result", result
  end

  def test_with_adapter_executes_block
    executed = false

    MultiJson.with_adapter(:json_gem) { executed = true }

    assert executed
  end

  def test_with_adapter_changes_adapter_inside_block
    inner_adapter = nil

    MultiJson.with_adapter(:json_gem) do
      inner_adapter = MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::JsonGem, inner_adapter
  end

  def test_with_adapter_captures_original_adapter
    MultiJson.use :json_gem
    original = MultiJson.adapter

    MultiJson.with_adapter(:json_gem) { nil }

    assert_equal original, MultiJson.adapter
  end

  def test_with_adapter_restores_on_exception
    MultiJson.use :json_gem

    assert_raises(RuntimeError) do
      MultiJson.with_adapter(:json_gem) { raise "error" }
    end

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_with_adapter_restores_exact_adapter
    MultiJson.use :json_gem
    expected = MultiJson.adapter

    MultiJson.with_adapter(:json_gem) { nil }

    assert_same expected, MultiJson.adapter
  end

  def test_with_adapter_uses_argument
    skip unless defined?(::Oj)
    MultiJson.use :json_gem

    MultiJson.with_adapter(:oj) do
      refute_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
      assert_equal MultiJson::Adapters::Oj, MultiJson.adapter
    end
  end
end
