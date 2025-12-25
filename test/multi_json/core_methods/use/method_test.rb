require_relative "../../../test_helper"

class UseMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_use_sets_adapter_and_returns_it
    result = MultiJson.use(:ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_use_resets_options_cache
    key = :"unique_test_key_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached" }
    MultiJson.use(:json_gem)

    assert_nil MultiJson::OptionsCache.dump.fetch(key, nil)
  end

  def test_adapter_equals_is_alias_for_use
    MultiJson.adapter = :ok_json

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_engine_equals_is_alias_for_use
    MultiJson.engine = :ok_json

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_use_always_resets_cache_even_on_error
    MultiJson::OptionsCache.dump.fetch(:test) { "value" }

    assert_raises(MultiJson::AdapterError) do
      MultiJson.use("nonexistent_adapter")
    end

    assert_nil MultiJson::OptionsCache.dump.fetch(:test, nil)
  end

  def test_use_calls_load_adapter_with_argument
    MultiJson.use :ok_json

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_use_stores_result_of_load_adapter
    result = MultiJson.use(:ok_json)

    assert_equal result, MultiJson.adapter
  end

  def test_use_passes_argument_to_load_adapter
    MultiJson.use :json_gem

    MultiJson.use(:ok_json)

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_use_stores_adapter_not_nil
    MultiJson.use(:ok_json)

    refute_nil MultiJson.adapter
    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_use_body_executes
    MultiJson.use :json_gem
    original = MultiJson.adapter

    MultiJson.use(:ok_json)

    refute_equal original, MultiJson.adapter
    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_use_resets_cache_via_options_cache_reset
    MultiJson::OptionsCache.dump.fetch(:use_test) { "cached_value" }

    assert_equal "cached_value", MultiJson::OptionsCache.dump.fetch(:use_test, nil)

    MultiJson.use(:json_gem)

    assert_nil MultiJson::OptionsCache.dump.fetch(:use_test, nil)
  end

  def test_use_returns_loaded_adapter
    result = MultiJson.use(:ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_use_calls_options_cache_reset_method
    reset_called = track_cache_reset { MultiJson.use(:json_gem) }

    assert reset_called, "OptionsCache.reset must be called"
  end

  def test_use_returns_loaded_adapter_class
    result = MultiJson.use(:ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
    refute_nil result
  end

  def test_use_stores_result_in_adapter_ivar
    MultiJson.use(:ok_json)

    stored = MultiJson.instance_variable_get(:@adapter)

    assert_equal MultiJson::Adapters::OkJson, stored
  end

  def test_use_calls_load_adapter
    result = MultiJson.use(:ok_json)

    # If load_adapter was not called, result would be :ok_json symbol, not the class
    assert_equal MultiJson::Adapters::OkJson, result
    refute_equal :ok_json, result
  end

  def test_use_passes_new_adapter_arg_to_load_adapter
    result = MultiJson.use(:ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
    refute_equal MultiJson::Adapters::JsonGem, result
  end

  private

  def track_cache_reset
    reset_called = false
    original = MultiJson::OptionsCache.method(:reset)
    silence_warnings { MultiJson::OptionsCache.define_singleton_method(:reset) { reset_called = original.call } }
    yield
    reset_called
  ensure
    silence_warnings { MultiJson::OptionsCache.define_singleton_method(:reset, original) }
  end
end
