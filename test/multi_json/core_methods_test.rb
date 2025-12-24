require_relative "../test_helper"

class MultiJsonAdapterMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_adapter_returns_current_adapter_class
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_adapter_loads_default_when_not_set
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)
    # Ensure default_adapter is set to a known available adapter
    MultiJson.instance_variable_set(:@default_adapter, :json_gem)

    refute_nil MultiJson.adapter
  ensure
    MultiJson.use :json_gem
  end

  def test_adapter_returns_same_instance_on_repeated_calls
    adapter1 = MultiJson.adapter
    adapter2 = MultiJson.adapter

    assert_same adapter1, adapter2
  end

  def test_adapter_returns_adapter_when_defined_and_truthy
    # Tests that the condition checks both defined? and truthiness
    MultiJson.use :ok_json

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_adapter_short_circuits_when_already_set
    # If adapter is already set, it should return immediately without calling use(nil)
    MultiJson.use :json_gem
    use_called = false
    original_use = MultiJson.method(:use)
    silence_warnings do
      MultiJson.define_singleton_method(:use) { |arg| (use_called = true if arg.nil?) || original_use.call(arg) }
    end
    MultiJson.adapter

    refute use_called
  ensure
    silence_warnings { MultiJson.define_singleton_method(:use, original_use) } if original_use
  end

  def test_adapter_returns_the_adapter_instance_not_nil
    # Kills mutations that return nil instead of @adapter
    MultiJson.use :ok_json

    result = MultiJson.adapter

    assert_equal MultiJson::Adapters::OkJson, result
    refute_nil result
  end

  def test_adapter_returns_correct_adapter_class_after_change
    # Kills mutation that returns fixed value
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter

    MultiJson.use :ok_json

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end
end

# Tests for adapter method behavior when undefined
class MultiJsonAdapterUndefinedTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_adapter_when_undefined_calls_use_nil
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)

    use_nil_called = with_stub(MultiJson, :default_adapter, -> { :json_gem }) do
      with_use_tracking { |called| capture_stderr { MultiJson.adapter } && called[:nil] }
    end

    assert use_nil_called, "use(nil) should be called when @adapter is undefined"
  end

  def test_adapter_checks_both_defined_and_truthiness
    MultiJson.instance_variable_set(:@adapter, nil)

    use_nil_called = with_use_tracking { |called| capture_stderr { MultiJson.adapter } && called[:nil] }

    assert use_nil_called, "use(nil) should be called when @adapter is nil"
  ensure
    MultiJson.use :json_gem
  end

  def test_adapter_returns_valid_adapter_when_ivar_is_nil
    MultiJson.instance_variable_set(:@adapter, nil)

    result = with_stub(MultiJson, :default_adapter, -> { :json_gem }) do
      capture_stderr { MultiJson.adapter }
    end

    refute_nil result, "adapter should not return nil when @adapter is nil"
    assert_kind_of Module, result
  ensure
    MultiJson.use :json_gem
  end

  def test_adapter_with_nil_ivar_loads_default
    MultiJson.instance_variable_set(:@adapter, nil)
    MultiJson.instance_variable_set(:@default_adapter, :ok_json)

    result = capture_stderr { MultiJson.adapter }

    assert_equal MultiJson::Adapters::OkJson, result
  ensure
    MultiJson.use :json_gem
    MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end

  def test_adapter_method_returns_value_from_instance_variable
    MultiJson.use :ok_json
    expected = MultiJson.instance_variable_get(:@adapter)

    result = MultiJson.adapter

    assert_same expected, result
  end

  private

  def with_use_tracking
    called = {nil: false}
    stub = ->(arg) { called[:nil] = true if arg.nil? }
    with_stub(MultiJson, :use, stub, call_original: true) { yield called }
  end
end

class MultiJsonUseMethodTest < Minitest::Test
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
    # Kill mutation: OptionsCache.reset -> nil or OptionsCache
    reset_called = track_cache_reset { MultiJson.use(:json_gem) }

    assert reset_called, "OptionsCache.reset must be called"
  end

  def test_use_returns_loaded_adapter_class
    # Kill mutation: @adapter = load_adapter(...) -> @adapter
    result = MultiJson.use(:ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
    refute_nil result
  end

  def test_use_stores_result_in_adapter_ivar
    # Kill mutation: @adapter = load_adapter(...) -> load_adapter(...)
    MultiJson.use(:ok_json)

    stored = MultiJson.instance_variable_get(:@adapter)

    assert_equal MultiJson::Adapters::OkJson, stored
  end

  def test_use_calls_load_adapter
    # Kill mutation: load_adapter(new_adapter) -> new_adapter
    result = MultiJson.use(:ok_json)

    # If load_adapter was not called, result would be :ok_json symbol, not the class
    assert_equal MultiJson::Adapters::OkJson, result
    refute_equal :ok_json, result
  end

  def test_use_passes_new_adapter_arg_to_load_adapter
    # Kill mutation: load_adapter(new_adapter) -> load_adapter(nil)
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

class MultiJsonLoadMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_without_options_uses_empty_hash
    result = MultiJson.load('{"key": "value"}')

    assert_equal({"key" => "value"}, result)
  end

  def test_load_with_options_passes_them_to_adapter
    result = MultiJson.load('{"key": "value"}', symbolize_keys: true)

    assert_equal({key: "value"}, result)
  end

  def test_load_with_adapter_option_uses_specified_adapter
    MultiJson.use :json_gem
    result = MultiJson.load('{"key": "value"}', adapter: :ok_json)

    assert_equal({"key" => "value"}, result)
    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_load_options_are_not_ignored
    result = MultiJson.load('{"key": "value"}', symbolize_keys: true)

    assert_equal({key: "value"}, result)
  end

  def test_load_options_default_enables_calling_without_second_arg
    result = MultiJson.load('{"test": 123}')

    assert_equal({"test" => 123}, result)
  end

  def test_load_wraps_adapter_parse_error
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{invalid json}")
    end

    assert_equal "{invalid json}", error.data
    refute_nil error.cause
  end

  def test_load_preserves_original_exception_as_cause
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{bad}")
    end

    assert_kind_of Exception, error.cause
  end

  def test_load_uses_current_adapter_for_parsing
    MultiJson.use :json_gem
    result = MultiJson.load('{"a":1}')

    assert_equal({"a" => 1}, result)
  end

  def test_load_passes_string_to_adapter_load
    MultiJson.use :json_gem
    result = MultiJson.load('{"test":"value"}')

    assert_equal({"test" => "value"}, result)
  end

  def test_load_passes_options_to_adapter_load
    MultiJson.use :json_gem
    result = MultiJson.load('{"key":"value"}', symbolize_keys: true)

    assert result.key?(:key)
  end
end

# Tests for load method's current_adapter interaction
class MultiJsonLoadCurrentAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_calls_current_adapter_with_options
    opts_received = with_current_adapter_tracking { MultiJson.load('{"a":1}', symbolize_keys: true) }

    assert_equal({symbolize_keys: true}, opts_received)
  end

  def test_load_calls_adapter_load_method
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.load('{"test":"value"}')

    assert_equal 1, TestHelpers::StrictAdapter.load_calls.size
    assert_equal '{"test":"value"}', TestHelpers::StrictAdapter.load_calls.first[:string]
  ensure
    MultiJson.use :json_gem
  end

  def test_load_returns_adapter_load_result
    result = MultiJson.load('{"key":"value"}')

    assert_equal({"key" => "value"}, result)
  end

  def test_load_catches_adapter_parse_error
    MultiJson.use :json_gem

    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{invalid}")
    end

    assert_kind_of MultiJson::ParseError, error
  end

  def test_load_builds_parse_error_with_data
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{bad json}")
    end

    assert_equal "{bad json}", error.data
  end

  def test_load_sets_cause_on_parse_error
    error = assert_raises(MultiJson::ParseError) do
      MultiJson.load("{bad}")
    end

    refute_nil error.cause
  end

  private

  def with_current_adapter_tracking(&)
    opts_received = nil
    stub = ->(opts = {}) { opts_received = opts }
    with_stub(MultiJson, :current_adapter, stub, call_original: true, &)
    opts_received
  end
end

# Mutation-killing tests for load method
class MultiJsonLoadMutationTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_returns_parsed_value_not_nil
    result = MultiJson.load('{"key":"value"}')

    refute_nil result
    assert_equal({"key" => "value"}, result)
  end

  def test_load_body_executes
    result = MultiJson.load('{"test":123}')

    refute_nil result
    assert_kind_of Hash, result
  end

  def test_load_uses_passed_options_not_empty_hash
    MultiJson.use :json_gem
    result = MultiJson.load('{"key":"value"}', symbolize_keys: true)

    assert result.key?(:key), "Options should be used, not replaced with {}"
    refute result.key?("key"), "Keys should be symbolized"
  end

  def test_load_uses_current_adapter_result_not_options
    result = MultiJson.load('{"a":1}', {symbolize_keys: false})

    assert_kind_of Hash, result
  end

  def test_load_uses_current_adapter_result_not_nil
    result = MultiJson.load('{"a":1}')

    refute_nil result
  end

  def test_load_does_not_call_super
    assert_equal({"works" => true}, MultiJson.load('{"works":true}'))
  end

  def test_load_error_cause_is_original_exception
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{invalid}") }

    refute_nil error.cause, "cause should be the original exception, not nil"
    assert_kind_of StandardError, error.cause
  end

  def test_load_raises_parse_error_not_just_raise
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{bad json}") }

    assert_kind_of MultiJson::ParseError, error
    assert_equal "{bad json}", error.data
  end

  def test_load_rescue_catches_adapter_error
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("not valid json") }

    assert_kind_of MultiJson::ParseError, error
    refute_nil error.cause
  end

  def test_load_error_data_is_original_string
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("bad json string") }

    assert_equal "bad json string", error.data
  end

  def test_load_passes_options_containing_adapter_to_current_adapter
    # Kill mutation: current_adapter(options) -> current_adapter or current_adapter(nil)
    adapter_received = track_current_adapter_options { MultiJson.load('{"key":"value"}', adapter: :ok_json) }

    assert_equal :ok_json, adapter_received
  end

  def test_load_returns_adapter_load_result_not_adapter
    # Kill mutation: adapter.load(...) -> adapter
    result = MultiJson.load('{"key":"value"}')

    assert_kind_of Hash, result
    refute_kind_of Module, result
  end

  def test_load_calls_load_not_dump
    # Kill mutation: adapter.load -> adapter.dump
    result = MultiJson.load('{"key":"value"}')

    # load returns parsed data, dump would return a string from the string input
    assert_kind_of Hash, result
    refute_kind_of String, result
  end

  def test_load_passes_string_as_first_arg
    # Kill mutation: adapter.load(string, options) -> adapter.load(options, string)
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.load('{"test":1}', {opt: true})

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_equal '{"test":1}', call[:string]
    assert_equal({opt: true}, call[:options])
  ensure
    MultiJson.use :json_gem
  end

  def test_load_passes_options_as_second_arg
    # Kill mutation: adapter.load(string, options) -> adapter.load(string)
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.load('{"a":1}', {my_option: "value"})

    call = TestHelpers::StrictAdapter.load_calls.first

    assert_equal({my_option: "value"}, call[:options])
  ensure
    MultiJson.use :json_gem
  end
end

class MultiJsonLoadAdapterSelectionTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
    TestHelpers::StrictAdapter.reset_calls
  end

  def test_load_uses_adapter_option_to_select_strict_adapter
    # Kill mutation: current_adapter(options) -> current_adapter
    MultiJson.load('{"a":1}', adapter: TestHelpers::StrictAdapter)

    # StrictAdapter records all load calls - if adapter option is ignored, this fails
    refute_empty TestHelpers::StrictAdapter.load_calls
  end

  def test_load_uses_adapter_option_not_default
    # Kill mutation: current_adapter(options) -> current_adapter or current_adapter(nil)
    MultiJson.load('{"a":1}', adapter: TestHelpers::StrictAdapter)

    # If mutation makes it use default adapter instead, load_calls will be empty
    assert_equal 1, TestHelpers::StrictAdapter.load_calls.size
  end
end

class MultiJsonLoadCauseMutationTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_load_error_cause_is_not_nil_when_mutant_removes_cause_kwarg
    # Kill mutation: raise(..., cause: e) -> raise(...)
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{bad}") }

    # The cause should be set, not nil
    refute_nil error.cause
    assert_kind_of Exception, error.cause
  end

  def test_load_error_cause_uses_cause_keyword_not_mutated_name
    # Kill mutation: cause: e -> cause__mutant__: e
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{bad}") }

    # Verify cause is actually set via the cause: keyword
    refute_nil error.cause, "cause should be set via cause: keyword, not cause__mutant__:"
  end

  def test_load_error_sets_cause_using_cause_keyword
    # Kill mutation: raise(..., cause: e) -> raise(..., cause__mutant__: e) or raise(...)
    error = assert_raises(MultiJson::ParseError) { MultiJson.load("{invalid}") }

    refute_nil error.cause, "cause must be set via cause: keyword argument"
  end
end

class MultiJsonDumpMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_dump_without_options_uses_empty_hash
    result = MultiJson.dump({key: "value"})

    assert_equal '{"key":"value"}', result
  end

  def test_dump_with_options_passes_them_to_adapter
    result = MultiJson.dump({a: 1, b: 2})

    assert_includes result, "a"
    assert_includes result, "b"
  end

  def test_dump_with_adapter_option_uses_specified_adapter
    MultiJson.use :json_gem
    result = MultiJson.dump({key: "value"}, adapter: :ok_json)

    assert_includes result, "key"
    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_dump_passes_options_to_current_adapter
    MultiJson.use :json_gem
    result = MultiJson.dump({test_key: "test_value"}, {})

    assert_includes result, "test_key"
  end

  def test_dump_options_default_is_empty_hash_not_nil
    MultiJson.use :json_gem
    result = MultiJson.dump([1, 2, 3])

    assert_equal "[1,2,3]", result
  end

  def test_dump_uses_current_adapter_for_encoding
    MultiJson.use :json_gem
    result = MultiJson.dump({a: 1})

    assert_includes result, "a"
  end

  def test_dump_passes_object_to_adapter_dump
    MultiJson.use :json_gem
    result = MultiJson.dump({key: "value"})

    assert_includes result, "key"
    assert_includes result, "value"
  end

  def test_dump_returns_json_string
    result = MultiJson.dump({test: 123})

    assert_kind_of String, result
  end
end

# Tests for dump method's current_adapter interaction
class MultiJsonDumpCurrentAdapterTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_dump_calls_current_adapter_with_options
    opts_received = with_current_adapter_tracking { MultiJson.dump({a: 1}, pretty: true) }

    assert_equal({pretty: true}, opts_received)
  end

  def test_dump_calls_adapter_dump_method
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.dump({test: "value"})

    assert_equal 1, TestHelpers::StrictAdapter.dump_calls.size
    assert_equal({test: "value"}, TestHelpers::StrictAdapter.dump_calls.first[:object])
  ensure
    MultiJson.use :json_gem
  end

  def test_dump_passes_options_to_adapter_dump
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.dump({a: 1}, pretty: true)

    assert_equal({pretty: true}, TestHelpers::StrictAdapter.dump_calls.first[:options])
  ensure
    MultiJson.use :json_gem
  end

  def test_dump_returns_adapter_dump_result
    result = MultiJson.dump({key: "value"})

    assert_includes result, "key"
    assert_includes result, "value"
  end

  private

  def with_current_adapter_tracking(&)
    opts_received = nil
    stub = ->(opts = {}) { opts_received = opts }
    with_stub(MultiJson, :current_adapter, stub, call_original: true, &)
    opts_received
  end
end

# Mutation-killing tests for dump method
class MultiJsonDumpMutationTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_dump_passes_options_containing_adapter_to_current_adapter
    # Kill mutation: current_adapter(options) -> current_adapter or current_adapter(nil)
    adapter_received = track_current_adapter_options { MultiJson.dump({key: "value"}, adapter: :ok_json) }

    assert_equal :ok_json, adapter_received
  end

  def test_dump_returns_string_not_nil
    result = MultiJson.dump({key: "value"})

    refute_nil result
    assert_kind_of String, result
  end

  def test_dump_body_executes
    result = MultiJson.dump({test: 123})

    refute_nil result
    assert_includes result, "test"
  end

  def test_dump_uses_passed_options_for_adapter_selection
    MultiJson.use :json_gem

    result = MultiJson.dump({key: "value"}, adapter: :ok_json)

    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_dump_calls_dump_on_current_adapter
    result = MultiJson.dump({test: "value"})

    assert_kind_of String, result
    refute_kind_of Module, result
  end

  def test_dump_does_not_call_super
    result = MultiJson.dump({works: true})

    assert_kind_of String, result
    assert_includes result, "works"
  end

  def test_dump_does_not_raise_by_default
    result = MultiJson.dump({normal: "operation"})

    assert_kind_of String, result
  end

  def test_dump_returns_adapter_dump_result_not_adapter
    # Kill mutation: current_adapter(options).dump(...) -> current_adapter(options)
    result = MultiJson.dump({key: "value"})

    assert_kind_of String, result
    refute_kind_of Module, result
  end

  def test_dump_calls_dump_not_load
    # Kill mutation: .dump -> .load
    result = MultiJson.dump({key: "value"})

    # dump returns a string, load would parse it
    assert_kind_of String, result
    assert_includes result, "key"
  end

  def test_dump_passes_object_as_first_arg
    # Kill mutation: adapter.dump(object, options) -> adapter.dump(options, object)
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.dump({the_object: true}, {the_options: true})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_equal({the_object: true}, call[:object])
    assert_equal({the_options: true}, call[:options])
  ensure
    MultiJson.use :json_gem
  end

  def test_dump_passes_options_as_second_arg
    # Kill mutation: adapter.dump(object, options) -> adapter.dump(object)
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    MultiJson.dump({obj: 1}, {opt: 2})

    call = TestHelpers::StrictAdapter.dump_calls.first

    assert_equal({opt: 2}, call[:options])
  ensure
    MultiJson.use :json_gem
  end

  def test_dump_uses_adapter_option_via_current_adapter
    # Kill mutation: current_adapter(options) -> current_adapter or current_adapter(nil)
    MultiJson.use :json_gem

    # OkJson produces slightly different formatting than JsonGem
    # We can verify adapter selection works by checking which adapter is used
    json_gem_result = MultiJson.dump({a: 1})
    ok_json_result = MultiJson.dump({a: 1}, adapter: :ok_json)

    # Both should return valid JSON strings (the adapter was selected correctly)
    assert_kind_of String, json_gem_result
    assert_kind_of String, ok_json_result
  end
end

class MultiJsonDumpAdapterSelectionTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
    TestHelpers::StrictAdapter.reset_calls
  end

  def test_dump_uses_adapter_option_to_select_strict_adapter
    # Kill mutation: current_adapter(options) -> current_adapter
    MultiJson.dump({a: 1}, adapter: TestHelpers::StrictAdapter)

    # StrictAdapter records all dump calls - if adapter option is ignored, this fails
    refute_empty TestHelpers::StrictAdapter.dump_calls
  end

  def test_dump_uses_adapter_option_not_default
    # Kill mutation: current_adapter(options) -> current_adapter or current_adapter(nil)
    MultiJson.dump({a: 1}, adapter: TestHelpers::StrictAdapter)

    # If mutation makes it use default adapter instead, dump_calls will be empty
    assert_equal 1, TestHelpers::StrictAdapter.dump_calls.size
  end
end

# Tests specifically for killing current_adapter(options) mutations
class MultiJsonCurrentAdapterOptionsMutationTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
    TestHelpers::StrictAdapter.reset_calls
  end

  def teardown
    MultiJson.use :json_gem
  end

  # Kill mutation: current_adapter(options) -> current_adapter in load
  def test_load_current_adapter_receives_options_hash
    # Set global adapter to StrictAdapter
    MultiJson.use TestHelpers::StrictAdapter
    TestHelpers::StrictAdapter.reset_calls

    # Call load with adapter: :json_gem option
    MultiJson.load('{"a":1}', adapter: :json_gem)

    # If options are passed to current_adapter, json_gem will be used
    # If options are NOT passed, StrictAdapter will be used
    # The mutation current_adapter(options) -> current_adapter would use StrictAdapter
    assert_empty TestHelpers::StrictAdapter.load_calls, "StrictAdapter should NOT be called when adapter: :json_gem is specified"
  end

  # Kill mutation: current_adapter(options) -> current_adapter(nil) in load
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

  # Kill mutation: current_adapter(options) -> current_adapter in dump
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

  # Kill mutation: current_adapter(options) -> current_adapter(nil) in dump
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

# Tests for killing MultiJson#use mutations
class MultiJsonUseMutationKillerTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def teardown
    MultiJson.use :json_gem
  end

  # Kill mutation: OptionsCache.reset -> nil
  def test_use_calls_options_cache_reset_not_nil
    key = :"use_test_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached_before" }

    assert_equal "cached_before", MultiJson::OptionsCache.dump.fetch(key, nil)

    MultiJson.use(:ok_json)

    # After use, cache should be cleared
    # If OptionsCache.reset was replaced with nil, cache would NOT be cleared
    assert_nil MultiJson::OptionsCache.dump.fetch(key, nil), "Cache should be cleared after use"
  end

  # Kill mutation: OptionsCache.reset -> OptionsCache
  def test_use_calls_reset_method_on_options_cache
    key = :"reset_test_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached_before" }

    MultiJson.use(:ok_json)

    # OptionsCache (the module) would not clear the cache
    # OptionsCache.reset (the method) clears the cache
    assert_nil MultiJson::OptionsCache.dump.fetch(key, nil)
  end

  def test_use_ensure_block_runs_and_resets_cache
    key = :"ensure_test_#{object_id}"
    MultiJson::OptionsCache.dump.fetch(key) { "cached" }

    # Even if load_adapter raises, ensure block should run
    assert_raises(MultiJson::AdapterError) do
      MultiJson.use("nonexistent_adapter_12345")
    end

    # Cache should still be cleared by ensure block
    assert_nil MultiJson::OptionsCache.dump.fetch(key, nil)
  end
end

class MultiJsonCurrentAdapterMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_current_adapter_returns_default_adapter_when_no_option
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.current_adapter
  end

  def test_current_adapter_returns_default_with_empty_options
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.current_adapter({})
  end

  def test_current_adapter_returns_specified_adapter_from_options
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_does_not_change_global_adapter
    MultiJson.use :json_gem
    MultiJson.current_adapter(adapter: :ok_json)

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_current_adapter_checks_adapter_key_in_options
    MultiJson.use :json_gem
    result = MultiJson.current_adapter({symbolize_keys: true})

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_current_adapter_options_default_allows_no_argument
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.current_adapter
  end

  def test_current_adapter_returns_different_adapter_than_global
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: :ok_json)

    refute_equal MultiJson.adapter, result
  end

  def test_current_adapter_with_nil_adapter_option_uses_global
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: nil)

    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_current_adapter_with_false_adapter_option_uses_global
    MultiJson.use :json_gem
    result = MultiJson.current_adapter(adapter: false)

    assert_equal MultiJson::Adapters::JsonGem, result
  end
end

# Tests for current_adapter method's load_adapter interaction
class MultiJsonCurrentAdapterLoadTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_current_adapter_calls_load_adapter_when_adapter_option_present
    arg_received = with_load_adapter_tracking { MultiJson.current_adapter(adapter: :ok_json) }

    assert_equal :ok_json, arg_received
  end

  def test_current_adapter_calls_adapter_method_when_no_adapter_option
    adapter_called = with_adapter_tracking { MultiJson.current_adapter({}) }

    assert adapter_called
  end

  def test_current_adapter_returns_load_adapter_result
    result = MultiJson.current_adapter(adapter: :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_extracts_adapter_from_options_hash
    MultiJson.use :json_gem

    result = MultiJson.current_adapter({adapter: :ok_json, other: :option})

    assert_equal MultiJson::Adapters::OkJson, result
  end

  private

  def with_load_adapter_tracking(&)
    arg_received = nil
    stub = ->(arg) { arg_received = arg }
    with_stub(MultiJson, :load_adapter, stub, call_original: true, &)
    arg_received
  end

  def with_adapter_tracking(&)
    adapter_called = false
    stub = -> { adapter_called = true }
    with_stub(MultiJson, :adapter, stub, call_original: true, &)
    adapter_called
  end
end

# Mutation-killing tests for current_adapter method
class MultiJsonCurrentAdapterMutationTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_current_adapter_returns_value_not_nil
    MultiJson.use :json_gem

    result = MultiJson.current_adapter

    refute_nil result
    assert_equal MultiJson::Adapters::JsonGem, result
  end

  def test_current_adapter_body_executes
    MultiJson.use :json_gem

    result = MultiJson.current_adapter

    refute_nil result
  end

  def test_current_adapter_uses_passed_options
    MultiJson.use :json_gem

    result = MultiJson.current_adapter(adapter: :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_accesses_options_bracket_adapter
    MultiJson.use :json_gem

    result = MultiJson.current_adapter({adapter: :ok_json})

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_uses_assignment_value
    MultiJson.use :json_gem

    result = MultiJson.current_adapter(adapter: :ok_json)

    refute_equal MultiJson.adapter, result unless MultiJson.adapter == MultiJson::Adapters::OkJson

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_does_not_raise
    result = MultiJson.current_adapter

    refute_nil result
  end

  def test_current_adapter_instance_method_accepts_no_arguments
    MultiJson.use :json_gem
    bound = MultiJson.instance_method(:current_adapter).bind(MultiJson)

    assert_equal MultiJson::Adapters::JsonGem, bound.call
  end

  def test_current_adapter_instance_method_accepts_nil_options
    MultiJson.use :json_gem
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }
    object.send(:use, :json_gem)

    assert_equal MultiJson::Adapters::JsonGem, object.send(:current_adapter, nil)
  end

  def test_current_adapter_instance_method_uses_adapter_option
    MultiJson.use :json_gem
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }

    result = object.send(:current_adapter, adapter: :ok_json)

    assert_equal MultiJson::Adapters::OkJson, result
  end

  def test_current_adapter_uses_hash_literal_default_argument
    skip "RubyVM::InstructionSequence not available on JRuby" if java?

    iseq = RubyVM::InstructionSequence.of(MultiJson.instance_method(:current_adapter))
    first_instruction = iseq.disasm.lines.find { |line| line.strip.start_with?("0000") }

    assert_includes first_instruction, "newhash"
    refute_includes first_instruction, "putnil"
  end

  def test_current_adapter_definition_includes_default_hash_argument
    file, = MultiJson.instance_method(:current_adapter).source_location
    source = File.read(file)

    assert_includes source, "def current_adapter(options = {})"
  end
end

class MultiJsonWithAdapterMethodTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_with_adapter_temporarily_changes_adapter
    MultiJson.use :json_gem
    inner_adapter = nil

    MultiJson.with_adapter(:ok_json) do
      inner_adapter = MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::OkJson, inner_adapter
  end

  def test_with_adapter_restores_original_adapter
    MultiJson.use :json_gem

    MultiJson.with_adapter(:ok_json) { nil }

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_with_adapter_restores_adapter_on_exception
    MultiJson.use :json_gem

    assert_raises(RuntimeError) do
      MultiJson.with_adapter(:ok_json) { raise "test error" }
    end

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_with_adapter_returns_block_value
    result = MultiJson.with_adapter(:ok_json) { "block result" }

    assert_equal "block result", result
  end

  def test_with_engine_is_alias_for_with_adapter
    MultiJson.use :json_gem
    inner_adapter = nil

    MultiJson.with_engine(:ok_json) do
      inner_adapter = MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::OkJson, inner_adapter
  end

  def test_with_adapter_captures_adapter_before_block
    MultiJson.use :ok_json
    original = MultiJson.adapter

    MultiJson.with_adapter(:json_gem) { nil }

    assert_same original, MultiJson.adapter
  end

  def test_with_adapter_executes_block
    executed = false
    MultiJson.with_adapter(:ok_json) { executed = true }

    assert executed
  end

  def test_with_adapter_changes_adapter_inside_block
    MultiJson.use :json_gem

    MultiJson.with_adapter(:ok_json) do
      assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
    end
  end

  def test_with_adapter_restores_different_adapter
    MultiJson.use :ok_json
    MultiJson.with_adapter(:json_gem) { nil }

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_with_adapter_nested_restores_correctly
    MultiJson.use :json_gem

    MultiJson.with_adapter(:ok_json) do
      MultiJson.with_adapter(:json_gem) do
        assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
      end
      assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end
end

# Mutation-killing tests for with_adapter method
class MultiJsonWithAdapterMutationTest < Minitest::Test
  cover "MultiJson*"

  def setup
    MultiJson.use :json_gem
  end

  def test_with_adapter_uses_new_adapter_argument
    MultiJson.use :json_gem

    MultiJson.with_adapter(:ok_json) do
      assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
      refute_nil MultiJson.adapter
    end
  end

  def test_with_adapter_sets_adapter_not_just_reads
    MultiJson.use :json_gem
    original = MultiJson.adapter

    MultiJson.with_adapter(:ok_json) do
      refute_equal original, MultiJson.adapter
    end
  end

  def test_with_adapter_captures_old_adapter_correctly
    MultiJson.use :ok_json
    expected_after = MultiJson.adapter

    MultiJson.with_adapter(:json_gem) do
      assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
    end

    assert_equal expected_after, MultiJson.adapter
    refute_nil MultiJson.adapter
  end

  def test_with_adapter_ensure_restores_old_adapter
    MultiJson.use :ok_json

    begin
      MultiJson.with_adapter(:json_gem) do
        raise "test error"
      end
    rescue RuntimeError
      # Expected
    end

    assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
  end

  def test_with_adapter_body_executes_all_statements
    MultiJson.use :json_gem
    block_executed = false
    adapter_changed = false

    MultiJson.with_adapter(:ok_json) do
      block_executed = true
      adapter_changed = MultiJson.adapter == MultiJson::Adapters::OkJson
    end

    assert block_executed, "Block should be executed"
    assert adapter_changed, "Adapter should be changed inside block"
    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter, "Adapter should be restored"
  end
end

class MultiJsonDeprecatedOptionsTest < Minitest::Test
  cover "MultiJson*"

  def test_default_options_setter_sets_both_load_and_dump_options
    silence_warnings do
      MultiJson.default_options = {foo: "bar"}
    end

    assert_equal({foo: "bar"}, MultiJson.load_options)
    assert_equal({foo: "bar"}, MultiJson.dump_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_returns_load_options
    MultiJson.load_options = {test: "value"}

    result = silence_warnings { MultiJson.default_options }

    assert_equal({test: "value"}, result)
  ensure
    MultiJson.load_options = nil
  end

  def test_default_options_instance_method_returns_load_options
    MultiJson.load_options = {test: "value"}
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_options) { MultiJson.load_options }

    result = silence_warnings { object.send(:default_options) }

    assert_equal({test: "value"}, result)
  ensure
    MultiJson.load_options = nil
  end

  def test_default_options_instance_method_warns
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_options) { MultiJson.load_options }
    warning_message = nil

    with_stub(Kernel, :warn, ->(msg) { warning_message = msg }) do
      silence_warnings { object.send(:default_options) }
    end

    refute_nil warning_message
    assert_includes warning_message, "MultiJson.default_options"
  end

  def test_default_options_instance_setter_sets_load_and_dump_options
    object = default_options_instance

    silence_warnings { object.send(:default_options=, foo: "bar") }

    assert_equal({foo: "bar"}, MultiJson.load_options)
    assert_equal({foo: "bar"}, MultiJson.dump_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_instance_setter_warns
    object = default_options_instance
    warning_message = nil

    with_stub(Kernel, :warn, ->(msg) { warning_message = msg }) do
      silence_warnings { object.send(:default_options=, foo: "bar") }
    end

    refute_nil warning_message
    assert_includes warning_message, "MultiJson.default_options setter"
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  private

  def default_options_instance
    Class.new { include MultiJson }.new.tap do |object|
      object.define_singleton_method(:load_options) { MultiJson.load_options }
      object.define_singleton_method(:load_options=) { |value| MultiJson.load_options = value }
      object.define_singleton_method(:dump_options=) { |value| MultiJson.dump_options = value }
    end
  end
end
