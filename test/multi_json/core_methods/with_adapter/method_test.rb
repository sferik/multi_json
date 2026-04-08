require_relative "../../../test_helper"

class WithAdapterMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_with_adapter_temporarily_changes_adapter
    MultiJson.use :json_gem
    inner_adapter = nil

    MultiJson.with_adapter(:json_gem) do
      inner_adapter = MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::JsonGem, inner_adapter
  end

  def test_with_adapter_restores_original_adapter
    MultiJson.use :json_gem

    MultiJson.with_adapter(:json_gem) { nil }

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_with_adapter_restores_adapter_on_exception
    MultiJson.use :json_gem

    assert_raises(RuntimeError) do
      MultiJson.with_adapter(:json_gem) { raise "test error" }
    end

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_with_adapter_returns_block_value
    result = MultiJson.with_adapter(:json_gem) { "block result" }

    assert_equal "block result", result
  end

  def test_with_engine_is_alias_for_with_adapter
    MultiJson.use :json_gem
    inner_adapter = nil

    MultiJson.with_engine(:json_gem) do
      inner_adapter = MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::JsonGem, inner_adapter
  end

  def test_with_adapter_captures_adapter_before_block
    MultiJson.use :json_gem
    original = MultiJson.adapter

    MultiJson.with_adapter(:json_gem) { nil }

    assert_same original, MultiJson.adapter
  end

  def test_with_adapter_executes_block
    executed = false
    MultiJson.with_adapter(:json_gem) { executed = true }

    assert executed
  end

  def test_with_adapter_changes_adapter_inside_block
    MultiJson.use :json_gem

    MultiJson.with_adapter(:json_gem) do
      assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
    end
  end

  def test_with_adapter_restores_different_adapter
    MultiJson.use :json_gem
    MultiJson.with_adapter(:json_gem) { nil }

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_with_adapter_nested_restores_correctly
    MultiJson.use :json_gem

    MultiJson.with_adapter(:json_gem) do
      MultiJson.with_adapter(:json_gem) do
        assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
      end
      assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end
end
