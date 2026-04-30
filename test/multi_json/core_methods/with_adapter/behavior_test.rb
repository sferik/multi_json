# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for with_adapter method behavior
class WithAdapterBehaviorTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_with_adapter_uses_new_adapter_argument
    MultiJSON.use :json_gem

    MultiJSON.with_adapter(:json_gem) do
      assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
      refute_nil MultiJSON.adapter
    end
  end

  def test_with_adapter_sets_adapter_not_just_reads
    skip unless defined?(::Oj)
    MultiJSON.use :json_gem
    original = MultiJSON.adapter

    MultiJSON.with_adapter(:oj) do
      refute_equal original, MultiJSON.adapter
    end
  end

  def test_with_adapter_captures_old_adapter_correctly
    MultiJSON.use :json_gem
    expected_after = MultiJSON.adapter

    MultiJSON.with_adapter(:json_gem) do
      assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
    end

    assert_equal expected_after, MultiJSON.adapter
    refute_nil MultiJSON.adapter
  end

  def test_with_adapter_ensure_restores_old_adapter
    MultiJSON.use :json_gem

    begin
      MultiJSON.with_adapter(:json_gem) do
        raise "test error"
      end
    rescue RuntimeError
      # Expected
    end

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_with_adapter_nested_restores_outer_override
    skip unless defined?(::Oj)
    MultiJSON.use :json_gem
    observed = {}
    MultiJSON.with_adapter(:oj) do
      MultiJSON.with_adapter(:json_gem) { observed[:inner] = MultiJSON.adapter }
      observed[:after_inner] = MultiJSON.adapter
    end

    # Inner sees its own override; after inner exits, outer's override
    # must be restored (not nil, and not the process default).
    assert_equal MultiJSON::Adapters::JsonGem, observed[:inner]
    assert_equal MultiJSON::Adapters::Oj, observed[:after_inner]
  end

  def test_with_adapter_can_override_only_generate_side
    MultiJSON.use :json_gem
    skip unless defined?(::Oj)

    MultiJSON.with_adapter(generate: :oj) do
      assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.parse_adapter
      assert_equal MultiJSON::Adapters::Oj, MultiJSON.generate_adapter
    end

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.generate_adapter
  end

  def test_with_adapter_body_executes_all_statements
    MultiJSON.use :json_gem
    block_executed = false
    adapter_changed = false

    MultiJSON.with_adapter(:json_gem) do
      block_executed = true
      adapter_changed = MultiJSON.adapter == MultiJSON::Adapters::JsonGem
    end

    assert block_executed, "Block should be executed"
    assert adapter_changed, "Adapter should be changed inside block"
    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter, "Adapter should be restored"
  end
end
