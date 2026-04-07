require_relative "../../../test_helper"

# Tests for with_adapter method behavior
class WithAdapterBehaviorTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_with_adapter_uses_new_adapter_argument
    MultiJson.use :json_gem

    MultiJson.with_adapter(:ok_json) do
      assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
      refute_nil MultiJson.adapter
    end
  end

  def test_with_adapter_sets_adapter_not_just_reads
    MultiJson.use :json_gem
    original = MultiJson.adapter

    MultiJson.with_adapter(:ok_json) do
      refute_equal original, MultiJson.adapter
    end
  end

  def test_with_adapter_captures_old_adapter_correctly
    MultiJson.use :ok_json
    expected_after = MultiJson.adapter

    MultiJson.with_adapter(:json_gem) do
      assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
    end

    assert_equal expected_after, MultiJson.adapter
    refute_nil MultiJson.adapter
  end

  def test_with_adapter_ensure_restores_old_adapter
    MultiJson.use :ok_json

    begin
      MultiJson.with_adapter(:json_gem) do
        raise "test error"
      end
    rescue RuntimeError
      # Expected
    end

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_with_adapter_nested_restores_outer_override
    MultiJson.use :ok_json
    observed = {}
    MultiJson.with_adapter(:json_gem) do
      MultiJson.with_adapter(:ok_json) { observed[:inner] = MultiJson.adapter }
      observed[:after_inner] = MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::OkJson, observed[:inner]
    assert_equal MultiJson::Adapters::JsonGem, observed[:after_inner]
  end

  def test_with_adapter_body_executes_all_statements
    MultiJson.use :json_gem
    block_executed = false
    adapter_changed = false

    MultiJson.with_adapter(:ok_json) do
      block_executed = true
      adapter_changed = MultiJson.adapter == MultiJson::Adapters::OkJson
    end

    assert block_executed, "Block should be executed"
    assert adapter_changed, "Adapter should be changed inside block"
    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter, "Adapter should be restored"
  end
end
