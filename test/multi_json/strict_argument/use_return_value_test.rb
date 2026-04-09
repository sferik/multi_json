# frozen_string_literal: true

require_relative "../../test_helper"

class UseReturnValueAndCacheResetTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @original = MultiJson.adapter
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_use_returns_loaded_adapter
    result = MultiJson.use(:json_gem)

    assert_equal MultiJson::Adapters::JsonGem, result
    refute_nil result
  end

  def test_use_calls_load_adapter
    called = track_load_adapter_calls { MultiJson.use(:json_gem) }

    assert called
  end

  private

  def track_load_adapter_calls(&)
    load_adapter_called = false
    original = MultiJson.method(:load_adapter)
    stub = lambda do |arg|
      load_adapter_called = true
      original.call(arg)
    end
    with_stub(MultiJson, :load_adapter, stub, &)
    load_adapter_called
  end

  public

  def test_use_stores_adapter
    MultiJson.use(:json_gem)

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.instance_variable_get(:@adapter)
  end

  def test_use_resets_options_cache
    MultiJson::OptionsCache.dump.fetch(:test_key) { "value" }

    MultiJson.use(:json_gem)

    assert_nil MultiJson::OptionsCache.dump.fetch(:test_key, nil)
  end

  def test_use_preserves_cache_on_error
    MultiJson::OptionsCache.dump.fetch(:error_test) { "cached" }

    assert_raises(MultiJson::AdapterError) do
      MultiJson.use("nonexistent")
    end

    assert_equal "cached", MultiJson::OptionsCache.dump.fetch(:error_test, nil)
  end
end
