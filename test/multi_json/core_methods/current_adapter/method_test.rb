# frozen_string_literal: true

require_relative "../../../test_helper"

class CurrentAdapterMethodTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_current_adapter_returns_default_adapter_when_no_option
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.current_adapter
  end

  def test_current_adapter_returns_default_with_empty_options
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.current_adapter(**{})
  end

  def test_current_adapter_returns_specified_adapter_from_options
    MultiJSON.use :json_gem
    result = MultiJSON.current_adapter(adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_does_not_change_global_adapter
    MultiJSON.use :json_gem
    MultiJSON.current_adapter(adapter: :json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_current_adapter_checks_adapter_key_in_options
    MultiJSON.use :json_gem
    result = MultiJSON.current_adapter(symbolize_names: true)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_options_default_allows_no_argument
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.current_adapter
  end

  def test_current_adapter_returns_different_adapter_than_global
    skip unless defined?(::Oj)
    MultiJSON.use :json_gem
    result = MultiJSON.current_adapter(adapter: :oj)

    refute_equal MultiJSON.adapter, result
  end

  def test_current_adapter_with_nil_adapter_option_uses_global
    MultiJSON.use :json_gem
    result = MultiJSON.current_adapter(adapter: nil)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_current_adapter_with_false_adapter_option_uses_global
    MultiJSON.use :json_gem
    result = MultiJSON.current_adapter(adapter: false)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end
end
