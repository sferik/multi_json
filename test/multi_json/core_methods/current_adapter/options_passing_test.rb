require_relative "../../../test_helper"

# Tests for current_adapter options parameter handling
class CurrentAdapterOptionsPassingTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_load_current_adapter_receives_options_hash
    # Set global adapter to StrictAdapter
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    # Call load with adapter: :json_gem option
    MultiJson.load('{"a":1}', adapter: :json_gem)

    # If options are passed to current_adapter, json_gem will be used
    # If options are NOT passed, StrictAdapter will be used
    assert_empty TestHelpers::StrictAdapter.load_calls, "StrictAdapter should NOT be called when adapter: :json_gem is specified"
  end

  def test_load_current_adapter_not_called_with_nil
    # Set global adapter to StrictAdapter
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    # Call load with adapter option
    MultiJson.load('{"a":1}', adapter: :json_gem)

    # current_adapter(nil) would use default adapter (StrictAdapter)
    # current_adapter(options) with adapter: :json_gem uses json_gem
    assert_empty TestHelpers::StrictAdapter.load_calls
  end

  def test_dump_current_adapter_receives_options_hash
    # Set global adapter to StrictAdapter
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    # Call dump with adapter: :json_gem option
    MultiJson.dump({a: 1}, adapter: :json_gem)

    # If options are passed to current_adapter, json_gem will be used
    # If options are NOT passed, StrictAdapter will be used
    assert_empty TestHelpers::StrictAdapter.dump_calls, "StrictAdapter should NOT be called when adapter: :json_gem is specified"
  end

  def test_dump_current_adapter_not_called_with_nil
    # Set global adapter to StrictAdapter
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    # Call dump with adapter option
    MultiJson.dump({a: 1}, adapter: :json_gem)

    # current_adapter(nil) would use default adapter (StrictAdapter)
    # current_adapter(options) with adapter: :json_gem uses json_gem
    assert_empty TestHelpers::StrictAdapter.dump_calls
  end

  def test_load_with_adapter_option_does_not_use_global_adapter
    MultiJson.use :json_gem
    tracking_adapter = create_load_tracking_adapter
    MultiJson.load('{"a":1}', adapter: tracking_adapter)

    assert tracking_adapter.load_called, "The specified adapter should be used"
  end

  def test_dump_with_adapter_option_does_not_use_global_adapter
    MultiJson.use :json_gem
    tracking_adapter = create_dump_tracking_adapter
    MultiJson.dump({a: 1}, adapter: tracking_adapter)

    assert tracking_adapter.dump_called, "The specified adapter should be used"
  end

  def create_load_tracking_adapter
    adapter = Module.new do
      class << self
        attr_accessor :load_called

        def load(string, _options = {}) = (@load_called = true) && JSON.parse(string)
      end
    end
    adapter.const_set(:ParseError, Class.new(StandardError))
    adapter.load_called = false
    adapter
  end

  def create_dump_tracking_adapter
    adapter = Module.new do
      class << self
        attr_accessor :dump_called

        def dump(object, _options = {}) = (@dump_called = true) && JSON.generate(object)
      end
    end
    adapter.const_set(:ParseError, Class.new(StandardError))
    adapter.dump_called = false
    adapter
  end
end
