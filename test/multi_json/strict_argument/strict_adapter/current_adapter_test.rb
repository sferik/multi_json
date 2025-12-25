require_relative "../../../test_helper"

class StrictAdapterCurrentAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_load_uses_current_adapter_with_options
    MultiJson.load('{"a":1}', adapter: :json_gem)

    assert_empty TestHelpers::StrictAdapter.load_calls
  end

  def test_dump_uses_current_adapter_with_options
    MultiJson.dump({a: 1}, adapter: :json_gem)

    assert_empty TestHelpers::StrictAdapter.dump_calls
  end

  def test_current_adapter_receives_options_hash
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: TestHelpers::StrictAdapter)

    assert_equal TestHelpers::StrictAdapter, result
  end

  def test_current_adapter_with_empty_hash_returns_global_adapter
    result = MultiJson.current_adapter({})

    assert_equal TestHelpers::StrictAdapter, result
  end

  def test_current_adapter_without_args_returns_global_adapter
    result = MultiJson.current_adapter

    assert_equal TestHelpers::StrictAdapter, result
  end
end
