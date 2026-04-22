# frozen_string_literal: true

require_relative "../../../test_helper"

class DumpAdapterSelectionTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
    TestHelpers::StrictAdapter.reset_calls
  end

  def test_dump_uses_adapter_option_to_select_strict_adapter
    MultiJSON.generate({a: 1}, adapter: TestHelpers::StrictAdapter)

    # StrictAdapter records all dump calls - if adapter option is ignored, this fails
    refute_empty TestHelpers::StrictAdapter.dump_calls
  end

  def test_dump_uses_adapter_option_not_default
    MultiJSON.generate({a: 1}, adapter: TestHelpers::StrictAdapter)

    assert_equal 1, TestHelpers::StrictAdapter.dump_calls.size
  end
end
