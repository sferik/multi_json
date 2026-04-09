# frozen_string_literal: true

require_relative "../../../test_helper"

class StrictAdapterDumpTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_dump_passes_object_as_first_argument
    MultiJson.dump({key: "value"})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_equal({key: "value"}, call[:object])
  end

  def test_dump_passes_options_hash_as_second_argument
    MultiJson.dump({a: 1}, pretty: true)

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert call[:options].key?(:pretty)
  end

  def test_dump_passes_empty_hash_when_no_options_given
    MultiJson.dump({a: 1})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_kind_of Hash, call[:options]
  end

  def test_dump_options_not_nil
    MultiJson.dump({a: 1})

    call = TestHelpers::StrictAdapter.dump_calls.first

    refute_nil call[:options], "Options should never be nil"
  end

  def test_dump_object_not_nil
    MultiJson.dump({a: 1})

    call = TestHelpers::StrictAdapter.dump_calls.first

    refute_nil call[:object], "Object should never be nil"
  end
end
