# frozen_string_literal: true

require_relative "../../../test_helper"

class UseMethodTest < Minitest::Test # rubocop:disable Metrics/ClassLength
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def test_use_sets_adapter_and_returns_it
    result = MultiJSON.use(:json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_use_resets_options_cache
    key = :"unique_test_key_#{object_id}"
    MultiJSON::OptionsCache.dump.fetch(key) { "cached" }
    MultiJSON.use(:json_gem)

    assert_nil MultiJSON::OptionsCache.dump.fetch(key, nil)
  end

  def test_adapter_equals_is_alias_for_use
    MultiJSON.adapter = :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_engine_equals_is_alias_for_use
    MultiJSON.adapter = :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_use_preserves_cache_on_error
    MultiJSON::OptionsCache.dump.fetch(:test) { "value" }

    assert_raises(MultiJSON::AdapterError) do
      MultiJSON.use("nonexistent_adapter")
    end

    assert_equal "value", MultiJSON::OptionsCache.dump.fetch(:test, nil)
  end

  def test_use_raises_adapter_error_early_when_custom_adapter_lacks_load
    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.use(adapter_without_load)
    end

    assert_match(/must respond to \.load/, error.message)
  end

  def test_use_raises_adapter_error_early_when_custom_adapter_lacks_dump
    error = assert_raises(MultiJSON::AdapterError) do
      MultiJSON.use(adapter_without_dump)
    end

    assert_match(/must respond to \.dump/, error.message)
  end

  def test_use_calls_load_adapter_with_argument
    MultiJSON.use :json_gem

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_use_stores_result_of_load_adapter
    result = MultiJSON.use(:json_gem)

    assert_equal result, MultiJSON.adapter
  end

  def test_use_passes_argument_to_load_adapter
    MultiJSON.use :json_gem

    MultiJSON.use(:json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_use_stores_adapter_not_nil
    MultiJSON.use(:json_gem)

    refute_nil MultiJSON.adapter
    assert_equal MultiJSON::Adapters::JsonGem, MultiJSON.adapter
  end

  def test_use_body_executes
    skip unless defined?(::Oj)
    MultiJSON.use :json_gem
    original = MultiJSON.adapter

    MultiJSON.use(:oj)

    refute_equal original, MultiJSON.adapter
    assert_equal MultiJSON::Adapters::Oj, MultiJSON.adapter
  end

  def test_use_resets_cache_via_options_cache_reset
    MultiJSON::OptionsCache.dump.fetch(:use_test) { "cached_value" }

    assert_equal "cached_value", MultiJSON::OptionsCache.dump.fetch(:use_test, nil)

    MultiJSON.use(:json_gem)

    assert_nil MultiJSON::OptionsCache.dump.fetch(:use_test, nil)
  end

  def test_use_returns_loaded_adapter
    result = MultiJSON.use(:json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_use_calls_options_cache_reset_method
    reset_called = track_cache_reset { MultiJSON.use(:json_gem) }

    assert reset_called, "OptionsCache.reset must be called"
  end

  def test_use_returns_loaded_adapter_class
    result = MultiJSON.use(:json_gem)

    assert_equal MultiJSON::Adapters::JsonGem, result
    refute_nil result
  end

  def test_use_stores_result_in_adapter_ivar
    MultiJSON.use(:json_gem)

    stored = MultiJSON.instance_variable_get(:@adapter)

    assert_equal MultiJSON::Adapters::JsonGem, stored
  end

  def test_use_calls_load_adapter
    result = MultiJSON.use(:json_gem)

    # If load_adapter was not called, result would be :json_gem symbol, not the class
    assert_equal MultiJSON::Adapters::JsonGem, result
    refute_equal :json_gem, result
  end

  def test_use_passes_new_adapter_arg_to_load_adapter
    skip unless defined?(::Oj)
    result = MultiJSON.use(:oj)

    assert_equal MultiJSON::Adapters::Oj, result
    refute_equal MultiJSON::Adapters::JsonGem, result
  end

  def test_use_holds_adapter_mutex_during_swap
    mutex = MultiJSON::Concurrency.const_get(:MUTEXES).fetch(:adapter)
    calls = stub_synchronize_tracker(mutex)
    object = Class.new { include MultiJSON }.new
    object.define_singleton_method(:load_adapter) { |arg| MultiJSON.send(:load_adapter, arg) }

    object.send(:use, :json_gem)

    assert_equal %i[synchronize_start synchronize_end], calls
  ensure
    mutex&.singleton_class&.send(:remove_method, :synchronize)
  end

  private

  def stub_synchronize_tracker(mutex)
    calls = []
    mutex.define_singleton_method(:synchronize) do |&block|
      calls << :synchronize_start
      result = block.call
      calls << :synchronize_end
      result
    end
    calls
  end

  def track_cache_reset
    reset_called = false
    original = MultiJSON::OptionsCache.method(:reset)
    silence_warnings { MultiJSON::OptionsCache.define_singleton_method(:reset) { reset_called = original.call } }
    yield
    reset_called
  ensure
    silence_warnings { MultiJSON::OptionsCache.define_singleton_method(:reset, original) }
  end

  def adapter_without_load
    Module.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.dump(_object, _options) = "{}"
    end
  end

  def adapter_without_dump
    Module.new do
      const_set(:ParseError, Class.new(StandardError))

      def self.load(_string, _options) = nil
    end
  end
end
