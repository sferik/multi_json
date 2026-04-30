# frozen_string_literal: true

require_relative "../../../test_helper"

class StrictAdapterCurrentAdapterTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_load_uses_current_adapter_with_options
    MultiJSON.load('{"a":1}', adapter: :json_gem)

    assert_empty TestHelpers::StrictAdapter.load_calls
  end

  def test_dump_uses_current_adapter_with_options
    MultiJSON.dump({a: 1}, adapter: :json_gem)

    assert_empty TestHelpers::StrictAdapter.dump_calls
  end

  def test_current_adapter_receives_options_hash
    MultiJSON.use :json_gem
    result = MultiJSON.current_adapter(adapter: TestHelpers::StrictAdapter)

    assert_equal TestHelpers::StrictAdapter, result
  end

  def test_current_adapter_with_empty_hash_returns_global_adapter
    result = MultiJSON.current_adapter({})

    assert_equal TestHelpers::StrictAdapter, result
  end

  def test_current_adapter_without_args_returns_global_adapter
    result = MultiJSON.current_adapter

    assert_equal TestHelpers::StrictAdapter, result
  end
end
