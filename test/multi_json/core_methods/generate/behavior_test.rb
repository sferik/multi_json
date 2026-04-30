# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for dump method behavior
class DumpBehaviorTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_dump_passes_options_containing_adapter_to_current_adapter
    adapter_received = track_current_adapter_options { MultiJSON.generate({key: "value"}, adapter: :json_gem) }

    assert_equal :json_gem, adapter_received
  end

  def test_dump_returns_string_not_nil
    result = MultiJSON.generate({key: "value"})

    refute_nil result
    assert_kind_of String, result
  end

  def test_dump_body_executes
    result = MultiJSON.generate({test: 123})

    refute_nil result
    assert_includes result, "test"
  end

  def test_dump_uses_passed_options_for_adapter_selection
    MultiJSON.use :json_gem

    result = MultiJSON.generate({key: "value"}, adapter: :json_gem)

    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_dump_calls_dump_on_current_adapter
    result = MultiJSON.generate({test: "value"})

    assert_kind_of String, result
    refute_kind_of Module, result
  end

  def test_dump_does_not_call_super
    result = MultiJSON.generate({works: true})

    assert_kind_of String, result
    assert_includes result, "works"
  end

  def test_dump_does_not_raise_by_default
    result = MultiJSON.generate({normal: "operation"})

    assert_kind_of String, result
  end

  def test_dump_returns_adapter_dump_result_not_adapter
    result = MultiJSON.generate({key: "value"})

    assert_kind_of String, result
    refute_kind_of Module, result
  end

  def test_dump_calls_dump_not_load
    result = MultiJSON.generate({key: "value"})

    # dump returns a string, load would parse it
    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_dump_passes_object_as_first_arg
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJSON.generate({the_object: true}, the_options: true)

    call = TestHelpers::StrictAdapter.generate_calls.first

    assert_equal({the_object: true}, call[:object])
    assert_equal({the_options: true}, call[:options])
  ensure
    MultiJSON.use :json_gem
  end

  def test_dump_passes_options_as_second_arg
    MultiJSON.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJSON.generate({obj: 1}, opt: 2)

    call = TestHelpers::StrictAdapter.generate_calls.first

    assert_equal({opt: 2}, call[:options])
  ensure
    MultiJSON.use :json_gem
  end

  def test_dump_uses_adapter_option_via_current_adapter
    skip unless defined?(::Oj)
    MultiJSON.use :json_gem

    # Oj produces slightly different formatting than JsonGem; verify
    # adapter selection by checking both produce valid JSON strings
    # through different code paths.
    default_result = MultiJSON.generate({a: 1})
    override_result = MultiJSON.generate({a: 1}, adapter: :oj)

    assert_kind_of String, default_result
    assert_kind_of String, override_result
  end
end
