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

  def test_returns_yajl_when_oj_excluded_and_yajl_loaded
    skip unless defined?(::Yajl)

    without_json_ext_parser do
      undefine_constants(:FastJsonparser) do
        result = MultiJSON::AdapterSelector.default_adapter_excluding(:oj)

        assert_equal MultiJSON::Adapters::Yajl, result
        # Exercise the adapter's instance methods so its source file's
        # coverage is tracked once it has been loaded by the line above.
        assert_equal({"a" => 1}, result.load('{"a":1}'))
        assert_equal '{"a":1}', result.dump({a: 1})
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
end
