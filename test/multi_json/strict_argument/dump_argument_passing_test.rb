# frozen_string_literal: true

require_relative "../../test_helper"

# Tests for dump method argument passing and return values
class DumpArgumentPassingTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_dump_returns_string_not_nil
    result = MultiJSON.dump({a: 1})

    refute_nil result
    assert_kind_of String, result
  end

  def test_dump_returns_json_string
    result = MultiJSON.dump({key: "value"})

    assert_equal '{"key":"value"}', result
  end

  def test_dump_actually_calls_adapter_dump
    adapter = create_tracking_adapter
    MultiJSON.use adapter

    MultiJSON.dump({test: true})

    assert adapter.dump_called, "dump should call adapter.dump"
  ensure
    MultiJSON.use :json_gem
  end

  def test_dump_uses_object_argument
    result = MultiJSON.dump({specific_key: "specific_value"})

    assert_includes result, "specific_key"
    assert_includes result, "specific_value"
  end

  def test_dump_passes_options_to_adapter
    adapter = create_tracking_adapter
    MultiJSON.use adapter

    MultiJSON.dump({a: 1}, custom_opt: true)

    assert adapter.received_options[:custom_opt], "options should be passed to adapter"
  ensure
    MultiJSON.use :json_gem
  end

  def test_dump_passes_options_to_current_adapter
    MultiJSON.use :json_gem

    result = MultiJSON.dump({x: 1}, adapter: :json_gem)

    refute_nil result
    assert_kind_of String, result
  end

  def test_dump_returns_adapter_result
    adapter = build_custom_adapter(dump_result: "custom_result")
    MultiJSON.use adapter

    assert_equal "custom_result", MultiJSON.dump({})
  ensure
    MultiJSON.use :json_gem
  end

  private

  def build_custom_adapter(dump_result: "{}")
    result = dump_result
    adapter = Module.new do
      class << self; attr_accessor :parse_error_class; end
      define_method(:load) { |*, **| {} }
      define_method(:dump) { |*, **| result }
      module_function :load, :dump
    end
    adapter.const_set(:ParseError, Class.new(StandardError))
    adapter
  end

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
