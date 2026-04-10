# frozen_string_literal: true

require_relative "../../test_helper"

# Tests for dump method argument passing and return values
class DumpArgumentPassingTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_dump_returns_string_not_nil
    result = MultiJson.dump({a: 1})

    refute_nil result
    assert_kind_of String, result
  end

  def test_dump_returns_json_string
    result = MultiJson.dump({key: "value"})

    assert_equal '{"key":"value"}', result
  end

  def test_dump_actually_calls_adapter_dump
    adapter = create_tracking_adapter
    MultiJson.use adapter

    MultiJson.dump({test: true})

    assert adapter.dump_called, "dump should call adapter.dump"
  ensure
    MultiJson.use :json_gem
  end

  def test_dump_uses_object_argument
    result = MultiJson.dump({specific_key: "specific_value"})

    assert_includes result, "specific_key"
    assert_includes result, "specific_value"
  end

  def test_dump_passes_options_to_adapter
    adapter = create_tracking_adapter
    MultiJson.use adapter

    MultiJson.dump({a: 1}, custom_opt: true)

    assert adapter.received_options[:custom_opt], "options should be passed to adapter"
  ensure
    MultiJson.use :json_gem
  end

  def test_dump_passes_options_to_current_adapter
    MultiJson.use :json_gem

    result = MultiJson.dump({x: 1}, adapter: :json_gem)

    refute_nil result
    assert_kind_of String, result
  end

  def test_dump_returns_adapter_result
    adapter = Module.new do
      class << self
        def load(*, **) = {}
        def dump(*, **) = "custom_result"
      end
    end
    adapter.const_set(:ParseError, Class.new(StandardError))
    MultiJson.use adapter

    assert_equal "custom_result", MultiJson.dump({})
  ensure
    MultiJson.use :json_gem
  end

  private

  def create_tracking_adapter
    adapter = TrackingDumpAdapter.dup
    adapter.reset_tracking
    adapter
  end

  module TrackingDumpAdapter
    class << self
      attr_accessor :dump_called, :received_options

      def reset_tracking
        @dump_called = false
        @received_options = {}
      end

      def dump(object, options = {})
        @dump_called = true
        @received_options = options
        JSON.generate(object)
      end

      def load(string, _options = {})
        JSON.parse(string)
      end
    end

    class ParseError < StandardError
    end
  end
end
