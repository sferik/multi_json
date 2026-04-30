# frozen_string_literal: true

require_relative "../../test_helper"

# Tests that verify method call arguments match exactly
class ArgumentVerificationTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    @original_adapter = MultiJSON.adapter
    @mock_adapter = create_mock_adapter
    MultiJSON.use @mock_adapter
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def create_mock_adapter
    mock = Module.new do
      class << self
        attr_accessor :parse_args, :generate_args

        def parse(*args) = (@parse_args = args) && {"result" => "parsed"}
        def generate(*args) = (@generate_args = args) && '{"result":"dumped"}'
      end
    end
    mock.const_set(:ParseError, Class.new(StandardError))
    mock
  end

  def test_load_passes_exactly_string_and_options
    MultiJSON.parse('{"test":1}', foo: :bar)

    assert_equal 2, @mock_adapter.parse_args.length
    assert_equal '{"test":1}', @mock_adapter.parse_args[0]
    assert_equal({foo: :bar}, @mock_adapter.parse_args[1])
  end

  def test_load_passes_empty_hash_as_default_options
    MultiJSON.parse('{"test":1}')

    assert_equal 2, @mock_adapter.parse_args.length
    assert_equal '{"test":1}', @mock_adapter.parse_args[0]
    assert_empty(@mock_adapter.parse_args[1])
  end

  def test_dump_passes_exactly_object_and_options
    MultiJSON.generate({test: 1}, bar: :baz)

    assert_equal 2, @mock_adapter.generate_args.length
    assert_equal({test: 1}, @mock_adapter.generate_args[0])
    assert_equal({bar: :baz}, @mock_adapter.generate_args[1])
  end

  def test_dump_passes_empty_hash_as_default_options
    MultiJSON.generate({test: 1})

    assert_equal 2, @mock_adapter.generate_args.length
    assert_equal({test: 1}, @mock_adapter.generate_args[0])
    assert_empty(@mock_adapter.generate_args[1])
  end
end

# Tests to verify options are actually used by current_adapter
class CurrentAdapterOptionsTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.use :json_gem
  end

  def teardown
    MultiJSON.use :json_gem
  end

  def test_load_with_adapter_option_calls_load_adapter
    load_adapter_called_with = nil
    original_load_adapter = MultiJSON.method(:load_adapter)

    MultiJSON.define_singleton_method(:load_adapter) do |arg|
      load_adapter_called_with = arg
      original_load_adapter.call(arg)
    end

    MultiJSON.parse('{"a":1}', adapter: :json_gem)

    assert_equal :json_gem, load_adapter_called_with
  ensure
    silence_warnings { MultiJSON.define_singleton_method(:load_adapter, original_load_adapter) }
  end

  def test_dump_with_adapter_option_calls_load_adapter
    load_adapter_called_with = nil
    original_load_adapter = MultiJSON.method(:load_adapter)

    MultiJSON.define_singleton_method(:load_adapter) do |arg|
      load_adapter_called_with = arg
      original_load_adapter.call(arg)
    end

    MultiJSON.generate({a: 1}, adapter: :json_gem)

    assert_equal :json_gem, load_adapter_called_with
  ensure
    silence_warnings { MultiJSON.define_singleton_method(:load_adapter, original_load_adapter) }
  end
end
