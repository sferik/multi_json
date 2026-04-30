# frozen_string_literal: true

require_relative "../../../test_helper"

class LoadAdapterSelectionTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
    TestHelpers::StrictAdapter.reset_calls
  end

  def test_load_uses_adapter_option_to_select_strict_adapter
    MultiJSON.parse('{"a":1}', adapter: TestHelpers::StrictAdapter)

    # StrictAdapter records all load calls - if adapter option is ignored, this fails
    refute_empty TestHelpers::StrictAdapter.parse_calls
  end

  def test_load_uses_adapter_option_not_default
    MultiJSON.parse('{"a":1}', adapter: TestHelpers::StrictAdapter)

    assert_equal 1, TestHelpers::StrictAdapter.parse_calls.size
  end
end
