# frozen_string_literal: true

require_relative "../../test_helper"

class LoadArgumentPassingTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_load_returns_parsed_data_not_nil
    result = MultiJSON.load('{"a":1}')

    refute_nil result
    assert_equal({"a" => 1}, result)
  end

  def test_load_returns_correct_parsed_structure
    result = MultiJSON.load('{"key":"value","num":42}')

    assert_equal({"key" => "value", "num" => 42}, result)
  end

  def test_load_actually_calls_adapter_load
    adapter = create_tracking_adapter
    MultiJSON.use adapter

    MultiJSON.load('{"test":true}')

    assert adapter.load_called, "load should call adapter.load"
  ensure
    MultiJSON.use :json_gem
  end

  def test_load_uses_string_argument
    result = MultiJSON.load('{"unique_key":"unique_value"}')

    assert_equal "unique_value", result["unique_key"]
  end

  def test_load_passes_options_to_adapter
    adapter = create_tracking_adapter
    MultiJSON.use adapter

    MultiJSON.load('{"a":1}', symbolize_names: true)

    assert adapter.received_options[:symbolize_names], "options should be passed to adapter"
  ensure
    MultiJSON.use :json_gem
  end

  def test_load_passes_options_to_current_adapter
    MultiJSON.use :json_gem

    result = MultiJSON.load('{"x":1}', adapter: :json_gem)

    refute_nil result
  end

  def test_load_returns_adapter_result
    adapter = build_custom_adapter(load_result: {"custom" => "result"})
    MultiJSON.use adapter

    assert_equal({"custom" => "result"}, MultiJSON.load("{}"))
  ensure
    MultiJSON.use :json_gem
  end

  def test_load_wraps_parse_error_from_adapter
    error = assert_raises(MultiJSON::ParseError) do
      MultiJSON.load("{invalid json}")
    end

    assert_kind_of MultiJSON::ParseError, error
    refute_nil error.cause
  end

  def test_load_error_includes_original_string
    error = assert_raises(MultiJSON::ParseError) do
      MultiJSON.load("{bad data}")
    end

    assert_equal "{bad data}", error.data
  end

  private

  def build_custom_adapter(load_result: {})
    result = load_result
    adapter = Module.new do
      define_method(:load) { |*, **| result }
      define_method(:dump) { |*, **| "{}" }
      module_function :load, :dump
    end
    adapter.const_set(:ParseError, Class.new(StandardError))
    adapter
  end

  def create_tracking_adapter
    adapter = TrackingLoadAdapter.dup
    adapter.reset_tracking
    adapter
  end

  module TrackingLoadAdapter
    class << self
      attr_accessor :load_called, :received_options

      def reset_tracking
        @load_called = false
        @received_options = {}
      end

      def load(string, options = {})
        @load_called = true
        @received_options = options
        JSON.parse(string)
      end

      def dump(object, _options = {})
        JSON.generate(object)
      end
    end

    ParseError = JSON::ParserError
  end
end
