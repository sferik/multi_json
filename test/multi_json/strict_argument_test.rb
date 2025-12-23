require_relative "../test_helper"

# These tests use a strict adapter that fails if options are missing/nil.
# This kills mutations that remove or change option passing.
class StrictAdapterLoadTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_load_passes_string_as_first_argument
    MultiJson.load('{"key":"value"}')

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_equal '{"key":"value"}', call[:string]
  end

  def test_load_passes_options_hash_as_second_argument
    MultiJson.load('{"a":1}', symbolize_keys: true)

    call = TestHelpers::StrictAdapter.load_calls.first

    assert call[:options].key?(:symbolize_keys)
  end

  def test_load_passes_empty_hash_when_no_options_given
    MultiJson.load('{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_kind_of Hash, call[:options]
  end

  def test_load_options_not_nil
    MultiJson.load('{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    refute_nil call[:options], "Options should never be nil"
  end

  def test_load_string_not_nil
    MultiJson.load('{"a":1}')

    call = TestHelpers::StrictAdapter.load_calls.first

    refute_nil call[:string], "String should never be nil"
  end

  def test_load_with_symbolize_keys_option
    result = MultiJson.load('{"key":"value"}', symbolize_keys: true)

    assert_equal({key: "value"}, result)
    call = TestHelpers::StrictAdapter.load_calls.first

    assert call[:options][:symbolize_keys]
  end
end

class StrictAdapterDumpTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_dump_passes_object_as_first_argument
    MultiJson.dump({key: "value"})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_equal({key: "value"}, call[:object])
  end

  def test_dump_passes_options_hash_as_second_argument
    MultiJson.dump({a: 1}, pretty: true)

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert call[:options].key?(:pretty)
  end

  def test_dump_passes_empty_hash_when_no_options_given
    MultiJson.dump({a: 1})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_kind_of Hash, call[:options]
  end

  def test_dump_options_not_nil
    MultiJson.dump({a: 1})

    call = TestHelpers::StrictAdapter.dump_calls.first

    refute_nil call[:options], "Options should never be nil"
  end

  def test_dump_object_not_nil
    MultiJson.dump({a: 1})

    call = TestHelpers::StrictAdapter.dump_calls.first

    refute_nil call[:object], "Object should never be nil"
  end
end

class StrictAdapterCurrentAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_load_uses_current_adapter_with_options
    MultiJson.load('{"a":1}', adapter: :json_gem)

    # If options weren't passed to current_adapter, it would use StrictAdapter
    # But with adapter: :json_gem, it should use JsonGem
    # The key is that current_adapter receives the options hash
    assert_empty TestHelpers::StrictAdapter.load_calls
  end

  def test_dump_uses_current_adapter_with_options
    MultiJson.dump({a: 1}, adapter: :json_gem)

    assert_empty TestHelpers::StrictAdapter.dump_calls
  end

  def test_current_adapter_receives_options_hash
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: TestHelpers::StrictAdapter)

    assert_equal TestHelpers::StrictAdapter, result
  end

  def test_current_adapter_with_empty_hash_returns_global_adapter
    result = MultiJson.current_adapter({})

    assert_equal TestHelpers::StrictAdapter, result
  end

  def test_current_adapter_without_args_returns_global_adapter
    result = MultiJson.current_adapter

    assert_equal TestHelpers::StrictAdapter, result
  end
end

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

    MultiJson.load('{"a":1}', adapter: :ok_json)

    assert_equal :ok_json, load_adapter_called_with
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

    MultiJson.dump({a: 1}, adapter: :ok_json)

    assert_equal :ok_json, load_adapter_called_with
  ensure
    silence_warnings { MultiJson.define_singleton_method(:load_adapter, original_load_adapter) }
  end
end
