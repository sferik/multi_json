require_relative "../../test_helper"
require_relative "adapter_selection_test"

class CurrentAdapterSelectionIntegrationTest < Minitest::Test
  cover "MultiJson*"

  include IntegrationTestSetup

  def test_current_adapter_defaults_to_current_adapter
    original = MultiJson.adapter
    MultiJson.use :json_gem

    assert_equal MultiJson.adapter, MultiJson.current_adapter
  ensure
    MultiJson.use original
  end

  def test_current_adapter_accepts_nil_options
    original = MultiJson.adapter
    MultiJson.use :json_gem

    assert_equal MultiJson.adapter, MultiJson.current_adapter(nil)
  ensure
    MultiJson.use original
  end

  def test_current_adapter_respects_adapter_option
    original = MultiJson.adapter
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::Oj, MultiJson.current_adapter(adapter: :oj)
  ensure
    MultiJson.use original
  end

  def test_settable_via_symbol
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_settable_via_case_insensitive_string
    MultiJson.use "Json_Gem"

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_settable_via_class
    adapter = Class.new
    MultiJson.use adapter

    assert_equal adapter, MultiJson.adapter
  end

  def test_settable_via_module
    adapter = Module.new
    MultiJson.use adapter

    assert_equal adapter, MultiJson.adapter
  end

  def test_throws_adapter_error_on_bad_input
    assert_raises(MultiJson::AdapterError) { MultiJson.use "bad adapter" }
  end

  def test_throws_adapter_error_on_invalid_type
    assert_raises(MultiJson::AdapterError) { MultiJson.use 12_345 }
  end
end
