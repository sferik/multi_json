require_relative "../../../test_helper"

class CurrentAdapterMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_current_adapter_returns_default_adapter_when_no_option
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.current_adapter
  end

  def test_current_adapter_returns_default_with_empty_options
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.current_adapter({})
  end

  def test_current_adapter_returns_specified_adapter_from_options
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_does_not_change_global_adapter
    MultiJson.use :json_gem
    MultiJson.current_adapter(adapter: :ok_json)

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_current_adapter_checks_adapter_key_in_options
    MultiJson.use :json_gem
    result = MultiJson.current_adapter({symbolize_keys: true})

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_current_adapter_options_default_allows_no_argument
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.current_adapter
  end

  def test_current_adapter_returns_different_adapter_than_global
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: :ok_json)

    refute_equal MultiJson.adapter, result
  end

  def test_current_adapter_with_nil_adapter_option_uses_global
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: nil)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_current_adapter_with_false_adapter_option_uses_global
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: false)

    assert_equal MultiJson::Adapters::JsonGem, result
  end
end
