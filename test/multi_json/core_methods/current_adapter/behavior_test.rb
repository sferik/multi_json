# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for current_adapter method behavior
class CurrentAdapterBehaviorTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_current_adapter_returns_value_not_nil
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter

    refute_nil result
    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_body_executes
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter

    refute_nil result
  end

  def test_current_adapter_uses_passed_options
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter(adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_accesses_options_bracket_adapter
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter(adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_accepts_positional_options_hash
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter({adapter: :json_gem})

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_uses_assignment_value
    MultiJSON.use :json_gem

    result = MultiJSON.current_adapter(adapter: :json_gem)

    refute_equal MultiJSON.adapter, result unless MultiJSON.adapter == MultiJSON::Adapters::JsonGem

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_does_not_raise
    result = MultiJSON.current_adapter

    refute_nil result
  end

  def test_current_generate_adapter_returns_generate_adapter
    MultiJSON.generate_adapter = :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.current_generate_adapter
  end

  def test_current_generate_adapter_uses_passed_options
    MultiJSON.generate_adapter = :json_gem

    result = MultiJSON.current_generate_adapter(adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_parse_adapter_returns_parse_adapter
    MultiJSON.parse_adapter = :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.current_parse_adapter(nil)
  end

  def test_current_parse_adapter_uses_passed_options
    MultiJSON.parse_adapter = :json_gem

    result = MultiJSON.current_parse_adapter(adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_parse_adapter_accepts_positional_options_hash
    MultiJSON.parse_adapter = :json_gem

    result = MultiJSON.current_parse_adapter({adapter: :json_gem})

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_generate_adapter_accepts_positional_options_hash
    MultiJSON.generate_adapter = :json_gem

    result = MultiJSON.current_generate_adapter({adapter: :json_gem})

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_instance_method_accepts_no_arguments
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.current_adapter
  end
end
