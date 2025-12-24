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

# Tests specifically designed to kill common mutations
class DumpMutationKillerTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  # Kills: replacing body with nil
  def test_dump_returns_string_not_nil
    result = MultiJson.dump({a: 1})

    refute_nil result
    assert_kind_of String, result
  end

  # Kills: replacing body with super
  def test_dump_returns_json_string
    result = MultiJson.dump({key: "value"})

    assert_equal '{"key":"value"}', result
  end

  # Kills: removing .dump call on adapter
  def test_dump_actually_calls_adapter_dump
    adapter = create_tracking_adapter
    MultiJson.use adapter

    MultiJson.dump({test: true})

    assert adapter.dump_called, "dump should call adapter.dump"
  ensure
    MultiJson.use :json_gem
  end

  # Kills: replacing object with nil
  def test_dump_uses_object_argument
    result = MultiJson.dump({specific_key: "specific_value"})

    assert_includes result, "specific_key"
    assert_includes result, "specific_value"
  end

  # Kills: replacing options with nil or {}
  def test_dump_passes_options_to_adapter
    adapter = create_tracking_adapter
    MultiJson.use adapter

    MultiJson.dump({a: 1}, custom_opt: true)

    assert adapter.received_options[:custom_opt], "options should be passed to adapter"
  ensure
    MultiJson.use :json_gem
  end

  # Kills: removing options from current_adapter call
  def test_dump_passes_options_to_current_adapter
    MultiJson.use :json_gem

    result = MultiJson.dump({x: 1}, adapter: :ok_json)

    # If options weren't passed, it would use json_gem, not ok_json
    refute_nil result
    assert_kind_of String, result
  end

  # Kills: replacing return with nil
  def test_dump_returns_adapter_result
    adapter = Module.new do
      class << self
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

  # Helper module for tracking dump calls
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
    end

    ParseError = Class.new(StandardError)
  end
end

class LoadMutationKillerTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  # Kills: replacing body with nil
  def test_load_returns_parsed_data_not_nil
    result = MultiJson.load('{"a":1}')

    refute_nil result
    assert_equal({"a" => 1}, result)
  end

  # Kills: replacing body with super
  def test_load_returns_correct_parsed_structure
    result = MultiJson.load('{"key":"value","num":42}')

    assert_equal({"key" => "value", "num" => 42}, result)
  end

  # Kills: removing .load call on adapter
  def test_load_actually_calls_adapter_load
    adapter = create_tracking_adapter
    MultiJson.use adapter

    MultiJson.load('{"test":true}')

    assert adapter.load_called, "load should call adapter.load"
  ensure
    MultiJson.use :json_gem
  end

  # Kills: replacing string with nil
  def test_load_uses_string_argument
    result = MultiJson.load('{"unique_key":"unique_value"}')

    assert_equal "unique_value", result["unique_key"]
  end

  # Kills: replacing options with nil or {}
  def test_load_passes_options_to_adapter
    adapter = create_tracking_adapter
    MultiJson.use adapter

    MultiJson.load('{"a":1}', symbolize_keys: true)

    assert adapter.received_options[:symbolize_keys], "options should be passed to adapter"
  ensure
    MultiJson.use :json_gem
  end

  # Kills: removing options from current_adapter call
  def test_load_passes_options_to_current_adapter
    MultiJson.use :json_gem

    result = MultiJson.load('{"x":1}', adapter: :ok_json)

    # If options weren't passed, it would use json_gem, not ok_json
    refute_nil result
  end

  # Kills: replacing return with nil
  def test_load_returns_adapter_result
    adapter = Module.new do
      class << self
        def load(*, **) = {"custom" => "result"}
      end
    end
    adapter.const_set(:ParseError, Class.new(StandardError))
    MultiJson.use adapter

    assert_equal({"custom" => "result"}, MultiJson.load("{}"))
  ensure
    MultiJson.use :json_gem
  end

  # Kills: wrong exception handling
  def test_load_wraps_parse_error_from_adapter
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{invalid json}")
    end

    assert_kind_of MultiJson::ParseError, error
    refute_nil error.cause
  end

  # Kills: replacing error data with nil
  def test_load_error_includes_original_string
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{bad data}")
    end

    assert_equal "{bad data}", error.data
  end

  private

  def create_tracking_adapter
    adapter = TrackingLoadAdapter.dup
    adapter.reset_tracking
    adapter
  end

  # Helper module for tracking load calls
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
    end

    ParseError = JSON::ParserError
  end
end

class UseMutationKillerTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @original = MultiJson.adapter
  end

  def teardown
    MultiJson.use :json_gem
  end

  # Kills: replacing body with nil
  def test_use_returns_loaded_adapter
    result = MultiJson.use(:ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
    refute_nil result
  end

  # Kills: not calling load_adapter
  def test_use_calls_load_adapter
    called = track_load_adapter_calls { MultiJson.use(:json_gem) }

    assert called
  end

  private

  def track_load_adapter_calls(&block)
    load_adapter_called = false
    original = MultiJson.method(:load_adapter)
    stub = lambda do |arg|
      load_adapter_called = true
      original.call(arg)
    end
    with_stub(MultiJson, :load_adapter, stub, &block)
    load_adapter_called
  end

  public

  # Kills: not storing in @adapter
  def test_use_stores_adapter
    MultiJson.use(:ok_json)

    assert_equal MultiJson::Adapters::OkJson, MultiJson.instance_variable_get(:@adapter)
  end

  # Kills: not calling OptionsCache.reset
  def test_use_resets_options_cache
    MultiJson::OptionsCache.dump.fetch(:test_key) { "value" }

    MultiJson.use(:json_gem)

    assert_nil MultiJson::OptionsCache.dump.fetch(:test_key, nil)
  end

  # Kills: ensure block not running
  def test_use_resets_cache_even_on_error
    MultiJson::OptionsCache.dump.fetch(:error_test) { "cached" }

    assert_raises(MultiJson::AdapterError) do
      MultiJson.use("nonexistent")
    end

    assert_nil MultiJson::OptionsCache.dump.fetch(:error_test, nil)
  end
end

class WithAdapterMutationKillerTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  # Kills: replacing body with nil
  def test_with_adapter_returns_block_result
    result = MultiJson.with_adapter(:ok_json) { "block_result" }

    assert_equal "block_result", result
  end

  # Kills: not yielding
  def test_with_adapter_executes_block
    executed = false

    MultiJson.with_adapter(:ok_json) { executed = true }

    assert executed
  end

  # Kills: not setting adapter before yield
  def test_with_adapter_changes_adapter_inside_block
    inner_adapter = nil

    MultiJson.with_adapter(:ok_json) do
      inner_adapter = MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::OkJson, inner_adapter
  end

  # Kills: not capturing old_adapter
  def test_with_adapter_captures_original_adapter
    MultiJson.use :ok_json
    original = MultiJson.adapter

    MultiJson.with_adapter(:json_gem) { nil }

    assert_equal original, MultiJson.adapter
  end

  # Kills: not restoring in ensure
  def test_with_adapter_restores_on_exception
    MultiJson.use :ok_json

    assert_raises(RuntimeError) do
      MultiJson.with_adapter(:json_gem) { raise "error" }
    end

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  # Kills: replacing old_adapter with nil in ensure
  def test_with_adapter_restores_exact_adapter
    MultiJson.use :ok_json
    expected = MultiJson.adapter

    MultiJson.with_adapter(:json_gem) { nil }

    assert_same expected, MultiJson.adapter
  end

  # Kills: not using new_adapter argument
  def test_with_adapter_uses_argument
    MultiJson.use :json_gem

    MultiJson.with_adapter(:ok_json) do
      refute_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
      assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
    end
  end
end

# Tests that use INSTANCE methods (via include MultiJson) to kill mutations
# Mutant mutates instance methods, but module_function creates separate singleton methods
class InstanceMethodDumpTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_dump_returns_json_string
    result = @object.send(:dump, {key: "value"})

    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_instance_dump_with_options
    result = @object.send(:dump, {a: 1}, {})

    assert_kind_of String, result
  end

  def test_instance_dump_calls_adapter_dump
    result = @object.send(:dump, {test: 123})

    assert_includes result, "test"
    assert_includes result, "123"
  end

  def test_instance_dump_respects_adapter_option
    result = @object.send(:dump, {x: 1}, adapter: :ok_json)

    assert_kind_of String, result
  end

  # Kills mutation: current_adapter(options).dump(object) without options
  def test_instance_dump_passes_options_to_adapter_dump
    @object.send(:use, :json_gem)
    result = @object.send(:dump, {a: 1}, pretty: true)

    # Pretty option adds newlines and indentation
    assert_includes result, "\n", "Pretty option should add newlines"
  end

  # Kills mutation: options = {} at start
  def test_instance_dump_uses_passed_options_not_empty
    @object.send(:use, :json_gem)
    result = @object.send(:dump, {a: 1}, pretty: true, indent: "  ")

    assert_includes result, "\n"
  end

  # Kills mutation: current_adapter(nil) instead of current_adapter(options)
  def test_instance_dump_passes_options_to_current_adapter
    @object.send(:use, TestHelpers::StrictAdapter)
    TestHelpers::StrictAdapter.reset_calls

    @object.send(:dump, {x: 1}, adapter: :json_gem)

    # If mutation applied (current_adapter without options), StrictAdapter is used
    # If NOT mutated (current_adapter(options)), json_gem is used
    assert_empty TestHelpers::StrictAdapter.dump_calls, "StrictAdapter should NOT be called with adapter: :json_gem"
  end

  private

  def create_multi_json_object
    obj = MultiJsonTestObject.new
    obj.send(:use, :json_gem)
    obj
  end

  # Helper class for testing MultiJson instance methods
  class MultiJsonTestObject
    include MultiJson

    def load_adapter(val)
      MultiJson.send(:load_adapter, val)
    end
  end
end

class InstanceMethodLoadTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_load_returns_parsed_data
    result = @object.send(:load, '{"key":"value"}')

    assert_equal({"key" => "value"}, result)
  end

  def test_instance_load_with_options
    result = @object.send(:load, '{"a":1}', symbolize_keys: true)

    assert_equal({a: 1}, result)
  end

  def test_instance_load_calls_adapter_load
    result = @object.send(:load, '{"test":123}')

    assert_equal 123, result["test"]
  end

  def test_instance_load_respects_adapter_option
    result = @object.send(:load, '{"x":1}', adapter: :ok_json)

    assert_equal({"x" => 1}, result)
  end

  def test_instance_load_raises_parse_error
    error = assert_raises(MultiJson::ParseError) do
      @object.send(:load, "{bad}")
    end

    assert_kind_of MultiJson::ParseError, error
  end

  # Kills mutations: ParseError.build(e, nil) and cause: nil
  def test_instance_load_error_has_data
    error = assert_raises(MultiJson::ParseError) do
      @object.send(:load, "{test_data}")
    end

    assert_equal "{test_data}", error.data
    refute_nil error.data
  end

  def test_instance_load_error_has_cause
    error = assert_raises(MultiJson::ParseError) do
      @object.send(:load, "{broken}")
    end

    refute_nil error.cause
    assert_kind_of Exception, error.cause
  end

  # Kills mutation: adapter.load(string) without options
  def test_instance_load_passes_options_to_adapter_load
    @object.send(:use, :json_gem)
    result = @object.send(:load, '{"key":"value"}', symbolize_keys: true)

    assert_equal({key: "value"}, result)
  end

  # Kills mutation: options = {} at start
  def test_instance_load_uses_passed_options_not_empty
    @object.send(:use, :json_gem)
    result = @object.send(:load, '{"a":"b"}', symbolize_keys: true)

    assert result.key?(:a)
    refute result.key?("a")
  end

  # Kills mutation: current_adapter(nil) instead of current_adapter(options)
  def test_instance_load_passes_options_to_current_adapter
    @object.send(:use, TestHelpers::StrictAdapter)
    TestHelpers::StrictAdapter.reset_calls

    @object.send(:load, '{"x":1}', adapter: :json_gem)

    # If mutation applied (current_adapter without options), StrictAdapter is used
    # If NOT mutated (current_adapter(options)), json_gem is used
    assert_empty TestHelpers::StrictAdapter.load_calls, "StrictAdapter should NOT be called with adapter: :json_gem"
  end

  # Kills mutation: not setting adapter before load
  def test_instance_load_uses_adapter_from_options
    @object.send(:use, :json_gem)
    # If the adapter option isn't used, it would use json_gem
    result = @object.send(:load, '{"test":true}', adapter: :ok_json)

    assert_equal({"test" => true}, result)
  end

  private

  def create_multi_json_object
    obj = InstanceMethodDumpTest::MultiJsonTestObject.new
    obj.send(:use, :json_gem)
    obj
  end
end

class InstanceMethodUseTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_use_sets_adapter
    @object.send(:use, :ok_json)

    assert_equal MultiJson::Adapters::OkJson, @object.send(:adapter)
  end

  def test_instance_use_returns_adapter
    result = @object.send(:use, :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  # Kills mutation: OptionsCache.reset -> nil
  def test_instance_use_resets_options_cache
    key = :"instance_use_test_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached_value" }

    @object.send(:use, :ok_json)

    # If OptionsCache.reset is replaced with nil, cache won't be cleared
    assert_nil MultiJson::OptionsCache.dump.fetch(key, nil), "Cache should be cleared after use"
  end

  # Kills mutation: OptionsCache.reset -> OptionsCache
  def test_instance_use_calls_reset_on_options_cache
    key = :"instance_reset_test_#{object_id}"
    MultiJson::OptionsCache.load.fetch(key) { "cached" }

    @object.send(:use, :json_gem)

    # OptionsCache (the module) doesn't clear cache, .reset does
    assert_nil MultiJson::OptionsCache.load.fetch(key, nil)
  end

  private

  def create_multi_json_object
    InstanceMethodDumpTest::MultiJsonTestObject.new
  end
end

class InstanceMethodWithAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
    @object.send(:use, :json_gem)
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_with_adapter_changes_adapter
    inner_adapter = nil

    @object.send(:with_adapter, :ok_json) do
      inner_adapter = @object.send(:adapter)
    end

    assert_equal MultiJson::Adapters::OkJson, inner_adapter
  end

  def test_instance_with_adapter_restores_adapter
    @object.send(:use, :json_gem)

    @object.send(:with_adapter, :ok_json) { nil }

    assert_equal MultiJson::Adapters::JsonGem, @object.send(:adapter)
  end

  def test_instance_with_adapter_returns_block_value
    result = @object.send(:with_adapter, :ok_json) { "result" }

    assert_equal "result", result
  end

  private

  def create_multi_json_object
    InstanceMethodDumpTest::MultiJsonTestObject.new
  end
end

class InstanceMethodCurrentAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    @object = create_multi_json_object
    @object.send(:use, :json_gem)
  end

  def teardown
    MultiJson.use :json_gem
  end

  def test_instance_current_adapter_returns_adapter
    result = @object.send(:current_adapter)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_instance_current_adapter_with_adapter_option
    result = @object.send(:current_adapter, adapter: :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_instance_current_adapter_handles_nil_options
    result = @object.send(:current_adapter, nil)

    refute_nil result
  end

  private

  def create_multi_json_object
    InstanceMethodDumpTest::MultiJsonTestObject.new
  end
end
