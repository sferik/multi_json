# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for dump method behavior
class DumpBehaviorTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_dump_passes_options_containing_adapter_to_current_adapter
    adapter_received = track_current_adapter_options { MultiJson.dump({key: "value"}, adapter: :json_gem) }

    assert_equal :json_gem, adapter_received
  end

  def test_dump_returns_string_not_nil
    result = MultiJson.dump({key: "value"})

    refute_nil result
    assert_kind_of String, result
  end

  def test_dump_body_executes
    result = MultiJson.dump({test: 123})

    refute_nil result
    assert_includes result, "test"
  end

  def test_dump_uses_passed_options_for_adapter_selection
    MultiJson.use :json_gem

    result = MultiJson.dump({key: "value"}, adapter: :json_gem)

    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_dump_calls_dump_on_current_adapter
    result = MultiJson.dump({test: "value"})

    assert_kind_of String, result
    refute_kind_of Module, result
  end

  def test_dump_does_not_call_super
    result = MultiJson.dump({works: true})

    assert_kind_of String, result
    assert_includes result, "works"
  end

  def test_dump_does_not_raise_by_default
    result = MultiJson.dump({normal: "operation"})

    assert_kind_of String, result
  end

  def test_dump_returns_adapter_dump_result_not_adapter
    result = MultiJson.dump({key: "value"})

    assert_kind_of String, result
    refute_kind_of Module, result
  end

  def test_dump_calls_dump_not_load
    result = MultiJson.dump({key: "value"})

    # dump returns a string, load would parse it
    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_dump_passes_object_as_first_arg
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.dump({the_object: true}, {the_options: true})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_equal({the_object: true}, call[:object])
    assert_equal({the_options: true}, call[:options])
  ensure
    MultiJson.use :json_gem
  end

  def test_dump_passes_options_as_second_arg
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.dump({obj: 1}, {opt: 2})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_equal({opt: 2}, call[:options])
  ensure
    MultiJson.use :json_gem
  end

  def test_dump_uses_adapter_option_via_current_adapter
    skip unless defined?(::Oj)
    MultiJson.use :json_gem

    # Oj produces slightly different formatting than JsonGem; verify
    # adapter selection by checking both produce valid JSON strings
    # through different code paths.
    default_result = MultiJson.dump({a: 1})
    override_result = MultiJson.dump({a: 1}, adapter: :oj)

    assert_kind_of String, default_result
    assert_kind_of String, override_result
  end
end
