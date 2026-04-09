require_relative "../../test_helper"
require "multi_json/adapter_selector"

# Tests for AdapterSelector#default_adapter_excluding, which is used by
# the FastJsonparser adapter to delegate dump operations to the fastest
# available adapter other than itself.
class DefaultAdapterExcludingTest < Minitest::Test
  cover "MultiJson::AdapterSelector*"

  def test_returns_an_adapter_class
    result = MultiJson::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

    assert_kind_of Class, result
  end

  def test_does_not_return_the_excluded_adapter
    result = MultiJson::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

    refute_equal MultiJson::Adapters::FastJsonparser, result if defined?(MultiJson::Adapters::FastJsonparser)
  end

  def test_returns_oj_when_oj_is_loaded_and_fast_jsonparser_is_excluded
    skip unless defined?(::Oj)

    result = MultiJson::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

    assert_equal MultiJson::Adapters::Oj, result
  end

  def test_returns_yajl_when_oj_excluded_and_yajl_loaded
    skip unless defined?(::Yajl)

    undefine_constants(:FastJsonparser) do
      result = MultiJson::AdapterSelector.default_adapter_excluding(:oj)

      assert_equal MultiJson::Adapters::Yajl, result
      # Exercise the adapter's instance methods so its source file's
      # coverage is tracked once it has been loaded by the line above.
      assert_equal({"a" => 1}, result.load('{"a":1}'))
      assert_equal '{"a":1}', result.dump({a: 1})
    end
  end

  def test_falls_back_to_installable_when_no_adapter_is_preloaded
    # All adapter constants undefined → loaded_adapter returns nil →
    # installable_adapter takes over, walks REQUIREMENT_MAP excluding the
    # named one, and returns the first installable adapter (Oj, since oj
    # is in the dev Gemfile and ranked first after fast_jsonparser).
    # Asserting on Oj specifically distinguishes the installable path
    # from the fallback path so mutation tests can tell them apart.
    skip unless defined?(::Oj)

    undefine_constants(:JSON, :Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser) do
      result = MultiJson::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

      assert_equal MultiJson::Adapters::Oj, result
    end
  end

  def test_falls_back_to_json_gem_when_no_other_adapter_is_available
    simulate_no_adapters do
      result = capture_stderr { MultiJson::AdapterSelector.default_adapter_excluding(:fast_jsonparser) }

      assert_equal MultiJson::Adapters::JsonGem, result
    end
  end

  def test_default_adapter_excluding_holds_mutex_during_detection
    mutex = MultiJson::Concurrency::DEFAULT_ADAPTER
    synchronized = false
    mutex.define_singleton_method(:synchronize) do |&block|
      synchronized = true
      block.call
    end

    MultiJson::AdapterSelector.default_adapter_excluding(:fast_jsonparser)

    assert synchronized
  ensure
    mutex&.singleton_class&.send(:remove_method, :synchronize)
  end
end
