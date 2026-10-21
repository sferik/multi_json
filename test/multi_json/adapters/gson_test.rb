# frozen_string_literal: true

require_relative "../../test_helper"

# The gson adapter was removed. Selecting it by name or constant falls
# back to the json_gem adapter, which every supported Ruby ships.
class GsonRemovalTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"

  def setup
    MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).clear
  end

  def teardown
    MultiJSON.use(nil)
  end

  def test_use_gson_symbol_selects_json_gem
    capture_warnings { MultiJSON.use(:gson) }

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_use_gson_string_selects_json_gem
    capture_warnings { MultiJSON.use("Gson") }

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_per_call_gson_adapter_parses_with_json_gem
    result = nil
    capture_warnings { result = MultiJSON.load('{"a":1}', adapter: :gson) }

    assert_equal({"a" => 1}, result)
  end

  def test_selecting_gson_warns_once_as_a_deprecation
    warnings = capture_warnings do
      MultiJSON.use(:gson)
      MultiJSON.use(:gson)
    end

    assert_equal [["MultiJSON's gson adapter was removed, so the json_gem adapter is used instead.", :deprecated]], warnings
  end

  def test_selecting_gson_records_its_deprecation_once
    capture_warnings { MultiJSON.use(:gson) }

    assert_includes MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN), :gson_adapter
  end

  def test_adapter_selector_maps_gson_on_its_own
    adapter = nil
    capture_warnings { adapter = MultiJSON::AdapterSelector.send(:load_adapter_by_name, "gson") }

    assert_equal MultiJSON::Adapters::JsonGem, adapter
  end

  def test_gson_constant_is_the_json_gem_adapter
    require "multi_json/adapters/gson"

    assert_same MultiJSON::Adapters::JsonGem, MultiJSON::Adapters::Gson
  end

  private

  def capture_warnings
    warnings = []
    original_warn = Kernel.method(:warn)
    silence_warnings { Kernel.define_singleton_method(:warn) { |message, category: nil| warnings << [message, category] } }
    yield
    warnings
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end
end
