require_relative "../../test_helper"

# Tests that verify method call arguments match exactly
class ArgumentVerificationTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @original_adapter = MultiJson.adapter
    @mock_adapter = create_mock_adapter
    MultiJson.use @mock_adapter
  end

  def teardown
    MultiJson.use :json_gem
  end

  def create_mock_adapter
    mock = Module.new do
      class << self
        attr_accessor :load_args, :dump_args

        def load(*args) = (@load_args = args) && {"result" => "parsed"}
        def dump(*args) = (@dump_args = args) && '{"result":"dumped"}'
      end
    end
    mock.const_set(:ParseError, Class.new(StandardError))
    mock
  end

  def test_load_passes_exactly_string_and_options
    MultiJson.load('{"test":1}', foo: :bar)

    assert_equal 2, @mock_adapter.load_args.length
    assert_equal '{"test":1}', @mock_adapter.load_args[0]
    assert_equal({foo: :bar}, @mock_adapter.load_args[1])
  end

  def test_load_passes_empty_hash_as_default_options
    MultiJson.load('{"test":1}')

    assert_equal 2, @mock_adapter.load_args.length
    assert_equal '{"test":1}', @mock_adapter.load_args[0]
    assert_empty(@mock_adapter.load_args[1])
  end

  def test_dump_passes_exactly_object_and_options
    MultiJson.dump({test: 1}, bar: :baz)

    assert_equal 2, @mock_adapter.dump_args.length
    assert_equal({test: 1}, @mock_adapter.dump_args[0])
    assert_equal({bar: :baz}, @mock_adapter.dump_args[1])
  end

  def test_dump_passes_empty_hash_as_default_options
    MultiJson.dump({test: 1})

    assert_equal 2, @mock_adapter.dump_args.length
    assert_equal({test: 1}, @mock_adapter.dump_args[0])
    assert_empty(@mock_adapter.dump_args[1])
  end
end

# Tests to verify options are actually used by current_adapter
class CurrentAdapterOptionsTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_load_with_adapter_option_calls_load_adapter
    load_adapter_called_with = nil
    original_load_adapter = MultiJson.method(:load_adapter)

    MultiJson.define_singleton_method(:load_adapter) do |arg|
      load_adapter_called_with = arg
      original_load_adapter.call(arg)
    end

    MultiJson.load('{"a":1}', adapter: :json_gem)

    assert_equal :json_gem, load_adapter_called_with
  ensure
    silence_warnings { MultiJson.define_singleton_method(:load_adapter, original_load_adapter) }
  end

  def test_dump_with_adapter_option_calls_load_adapter
    load_adapter_called_with = nil
    original_load_adapter = MultiJson.method(:load_adapter)

    MultiJson.define_singleton_method(:load_adapter) do |arg|
      load_adapter_called_with = arg
      original_load_adapter.call(arg)
    end

    MultiJson.dump({a: 1}, adapter: :json_gem)

    assert_equal :json_gem, load_adapter_called_with
  ensure
    silence_warnings { MultiJson.define_singleton_method(:load_adapter, original_load_adapter) }
  end
end
