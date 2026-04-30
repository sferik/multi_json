# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "loaded_adapter_test"
require "multi_json/adapter_selector"

# Tests for AdapterSelector#default_adapter_excluding, which is used by
# the FastJsonparser adapter to delegate dump operations to the fastest
# available adapter other than itself.
class DefaultAdapterExcludingTest < Minitest::Test
  cover "MultiJSON::AdapterSelector*"
  include LoadedAdapterTestHelpers

  def test_returns_an_adapter_class
    result = MultiJSON::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

    assert_kind_of Class, result
  end

  def test_generate_default_adapter_excluding_prefers_generate_order
    result = MultiJSON::AdapterSelector.default_adapter_excluding(:fast_jsonparser, operation: :generate)

    assert_kind_of Class, result
    assert_equal MultiJSON::Adapters::JsonGem, result if defined?(::JSON::Ext::Parser)
  end

  def test_does_not_return_the_excluded_adapter
    result = MultiJSON::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

    refute_equal MultiJSON::Adapters::FastJsonparser, result if defined?(MultiJSON::Adapters::FastJsonparser)
  end

  def test_returns_json_gem_when_fast_jsonparser_is_excluded
    skip "JRuby's ADAPTERS hash leads with jr_jackson" if TestHelpers.java?
    with_json_ext_parser do
      result = MultiJSON::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

      assert_equal MultiJSON::Adapters::JsonGem, result
    end
  end

  # ``break_requirements`` disables installable_adapter so the
  # loaded_adapter path drives selection: with json_gem first in
  # PARSE_ADAPTERS, requiring "json" succeeds and short-circuits before
  # yajl gets a turn. The two #parse / #generate assertions exercise
  # the adapter's instance methods so its source file's coverage is
  # tracked once it has been loaded.
  def test_returns_yajl_when_oj_excluded_and_yajl_loaded # rubocop:disable Metrics/MethodLength
    skip unless defined?(::Yajl)
    break_requirements do
      without_json_ext_parser do
        undefine_constants(:FastJsonparser, :JrJackson) do
          result = MultiJSON::AdapterSelector.default_adapter_excluding(:oj)

          assert_equal MultiJSON::Adapters::Yajl, result
          assert_equal({"a" => 1}, result.parse('{"a":1}'))
          assert_equal '{"a":1}', result.generate({a: 1})
        end
      end
    end
  end

  def test_falls_back_to_installable_when_no_adapter_is_preloaded
    # All adapter constants undefined → loaded_adapter returns nil →
    # installable_adapter takes over, walks REQUIREMENT_MAP excluding
    # the named one, and returns the first installable adapter. We
    # exclude :json_gem on purpose so the assertion lands on a
    # different adapter than the hardcoded fallback (also :json_gem):
    # on MRI the next installable is :fast_jsonparser, which both
    # rules out the fallback path AND verifies that ``excluding:``
    # actually skipped :json_gem during installable detection.
    skip "JRuby's ADAPTERS hash leads with jr_jackson" if TestHelpers.java?
    undefine_constants(:JSON, :Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser) do
      result = MultiJSON::AdapterSelector.default_adapter_excluding(:json_gem)

      assert_equal MultiJSON::Adapters::FastJsonparser, result
    end
  end

  def test_falls_back_to_json_gem_when_no_other_adapter_is_available
    simulate_no_adapters do
      result = capture_stderr { MultiJSON::AdapterSelector.default_adapter_excluding(:fast_jsonparser) }

      assert_equal MultiJSON::Adapters::JsonGem, result
    end
  end

  def test_default_adapter_excluding_holds_mutex_during_detection
    mutex = MultiJSON::Concurrency.const_get(:MUTEXES).fetch(:default_adapter)
    synchronized = false
    mutex.define_singleton_method(:synchronize) do |&block|
      synchronized = true
      block.call
    end

    MultiJSON::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

    assert synchronized
  ensure
    mutex&.singleton_class&.send(:remove_method, :synchronize)
  end

  def test_adapter_preferences_rejects_unknown_operation
    error = assert_raises(ArgumentError) do
      MultiJSON::AdapterSelector.send(:adapter_preferences, :wat)
    end

    assert_includes error.message, ":wat"
  end
end
