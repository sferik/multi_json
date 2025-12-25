require_relative "../../../test_helper"

class LoadAdapterSelectionTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
    TestHelpers::StrictAdapter.reset_calls
  end

  def test_load_uses_adapter_option_to_select_strict_adapter
    MultiJson.load('{"a":1}', adapter: TestHelpers::StrictAdapter)

    # StrictAdapter records all load calls - if adapter option is ignored, this fails
    refute_empty TestHelpers::StrictAdapter.load_calls
  end

  def test_load_uses_adapter_option_not_default
    MultiJson.load('{"a":1}', adapter: TestHelpers::StrictAdapter)

    assert_equal 1, TestHelpers::StrictAdapter.load_calls.size
  end
end
