# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for dump method's current_adapter interaction
class DumpCurrentAdapterTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_dump_calls_current_adapter_with_options
    opts_received = with_current_adapter_tracking { MultiJSON.dump({a: 1}, pretty: true) }

    assert_equal({pretty: true}, opts_received)
  end

  def test_dump_calls_adapter_dump_method
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJSON.dump({test: "value"})

    assert_equal 1, TestHelpers::StrictAdapter.dump_calls.size
    assert_equal({test: "value"}, TestHelpers::StrictAdapter.dump_calls.first[:object])
  ensure
    MultiJSON.use :json_gem
  end

  def test_dump_passes_options_to_adapter_dump
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJSON.dump({a: 1}, pretty: true)

    assert_equal({pretty: true}, TestHelpers::StrictAdapter.dump_calls.first[:options])
  ensure
    MultiJSON.use :json_gem
  end

  def test_dump_returns_adapter_dump_result
    result = MultiJSON.dump({key: "value"})

    assert_includes result, "key"
    assert_includes result, "value"
  end

  private

  def with_current_adapter_tracking(&)
    opts_received = nil
    stub = ->(opts = {}) { opts_received = opts }
    with_stub(MultiJSON, :current_adapter, stub, call_original: true, &)
    opts_received
  end
end
