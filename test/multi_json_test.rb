require_relative "test_helper"
require_relative "support/options_tests"

# Load all available adapters
MultiJson::REQUIREMENT_MAP.each_value do |library|
  require library
rescue LoadError
  next
end

module MultiJsonTestSetup
  def setup
    skip "java based implementations" if TestHelpers.java?
    MultiJson.use :oj
    return unless MultiJson.instance_variable_defined?(:@default_adapter)

    MultiJson.remove_instance_variable(:@default_adapter)
  end
end

class MultiJsonAdapterSelectionTest < Minitest::Test
  cover "MultiJson*"

  include MultiJsonTestSetup

  def test_defaults_to_best_available_gem
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)

    assert_equal expected_default_adapter, MultiJson.adapter.to_s
  end

  def test_adapter_loads_default_when_not_set
    original = MultiJson.adapter
    clear_adapter_state
    calls = []
    result = with_use_calls(calls) { MultiJson.adapter }

    assert_kind_of Module, result
    assert_equal [nil], calls
  ensure
    MultiJson.use original
  end

  def test_adapter_reloads_when_adapter_is_defined_as_nil
    original = MultiJson.adapter
    MultiJson.instance_variable_set(:@adapter, nil)

    calls = []
    result = with_use_calls(calls) { MultiJson.adapter }

    assert_kind_of Module, result
    assert_equal [nil], calls
  ensure
    MultiJson.use original
  end

  def test_adapter_does_not_define_adapter_when_load_fails
    original = MultiJson.adapter
    clear_adapter_state

    assert_raises(StandardError) do
      with_stub(MultiJson, :use, ->(*) { raise StandardError, "boom" }) { MultiJson.adapter }
    end

    refute MultiJson.instance_variable_defined?(:@adapter)
  ensure
    MultiJson.use original
  end

  def test_adapter_handles_nil_result_without_recursion
    original = MultiJson.adapter
    result, use_calls = adapter_result_with_nil_recursion

    assert_nil result
    assert_equal 1, use_calls
  ensure
    MultiJson.use original
  end

  def test_adapter_returns_existing_without_reloading
    original = MultiJson.adapter
    MultiJson.use :json_gem

    calls = []
    result = with_use_calls(calls) { MultiJson.adapter }

    assert_equal MultiJson::Adapters::JsonGem, result
    assert_empty calls
  ensure
    MultiJson.use original
  end

  def test_looks_for_adapter_even_if_adapter_variable_is_nil
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)

    result = with_stub(MultiJson, :default_adapter, -> { :ok_json }) { MultiJson.adapter }

    assert_equal MultiJson::Adapters::OkJson, result
  end

  private

  def clear_adapter_state
    MultiJson.send(:remove_instance_variable, :@adapter) if MultiJson.instance_variable_defined?(:@adapter)
    MultiJson.send(:remove_instance_variable, :@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)
  end

  def with_use_calls(calls, &block)
    result = nil
    with_stub(MultiJson, :use, ->(value) { calls << value }, call_original: true) { result = block.call }
    result
  end

  def adapter_result_with_nil_recursion
    clear_adapter_state
    use_calls = 0
    result = nil
    stub = lambda do |*|
      use_calls += 1
      MultiJson.instance_variable_set(:@adapter, nil)
    end

    with_stub(MultiJson, :use, stub) { result = MultiJson.adapter }

    [result, use_calls]
  end
end

class MultiJsonCurrentAdapterSelectionTest < Minitest::Test
  cover "MultiJson*"

  include MultiJsonTestSetup

  def test_current_adapter_defaults_to_current_adapter
    original = MultiJson.adapter
    MultiJson.use :json_gem

    assert_equal MultiJson.adapter, MultiJson.current_adapter
  ensure
    MultiJson.use original
  end

  def test_current_adapter_accepts_nil_options
    original = MultiJson.adapter
    MultiJson.use :json_gem

    assert_equal MultiJson.adapter, MultiJson.current_adapter(nil)
  ensure
    MultiJson.use original
  end

  def test_current_adapter_respects_adapter_option
    original = MultiJson.adapter
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::Oj, MultiJson.current_adapter(adapter: :oj)
  ensure
    MultiJson.use original
  end

  def test_settable_via_symbol
    MultiJson.use :json_gem

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_settable_via_case_insensitive_string
    MultiJson.use "Json_Gem"

    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def test_settable_via_class
    adapter = Class.new
    MultiJson.use adapter

    assert_equal adapter, MultiJson.adapter
  end

  def test_settable_via_module
    adapter = Module.new
    MultiJson.use adapter

    assert_equal adapter, MultiJson.adapter
  end

  def test_throws_adapter_error_on_bad_input
    assert_raises(MultiJson::AdapterError) { MultiJson.use "bad adapter" }
  end

  def test_throws_adapter_error_on_invalid_type
    assert_raises(MultiJson::AdapterError) { MultiJson.use 12_345 }
  end
end

class MultiJsonInstanceAdapterSelectionTest < Minitest::Test
  cover "MultiJson*"

  include MultiJsonTestSetup

  def test_instance_adapter_loads_default_when_not_set
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }

    calls = []
    result = nil

    with_stub(object, :use, ->(value) { calls << value }, call_original: true) do
      result = object.send(:adapter)
    end

    assert_kind_of Module, result

    assert_equal [nil], calls
  end

  def test_instance_adapter_reloads_when_defined_as_nil
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }
    object.instance_variable_set(:@adapter, nil)

    calls = []
    result = nil

    with_stub(object, :use, ->(value) { calls << value }, call_original: true) do
      result = object.send(:adapter)
    end

    assert_kind_of Module, result

    assert_equal [nil], calls
  end

  def test_instance_adapter_returns_existing_without_reloading
    object = Class.new { include MultiJson }.new
    object.define_singleton_method(:load_adapter) { |value| MultiJson.send(:load_adapter, value) }
    object.send(:use, :json_gem)

    calls = []
    result = nil

    with_stub(object, :use, ->(value) { calls << value }, call_original: true) do
      result = object.send(:adapter)
    end

    assert_equal MultiJson::Adapters::JsonGem, result

    assert_empty calls
  end

  def test_gives_access_to_original_error_when_raising_adapter_error
    exception = get_exception(MultiJson::AdapterError) { MultiJson.use "foobar" }

    assert_instance_of LoadError, exception.cause
    assert_match %r{adapters/foobar}, exception.message
    assert_includes exception.message, "Did not recognize your adapter specification"
  end

  def test_can_set_adapter_for_block
    MultiJson.with_adapter(:json_gem) do
      MultiJson.with_engine(:ok_json) do
        assert_equal MultiJson::Adapters::OkJson, MultiJson.adapter
      end

      assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
    end

    assert_equal MultiJson::Adapters::Oj, MultiJson.adapter
  end

  def test_restores_adapter_after_exception
    MultiJson.use :json_gem
    original_adapter = MultiJson.adapter

    assert_raises(StandardError) { MultiJson.with_adapter(:oj) { raise StandardError } }

    assert_equal original_adapter, MultiJson.adapter
  end
end

class MultiJsonBehaviorTest < Minitest::Test
  cover "MultiJson*"

  include MultiJsonTestSetup

  def test_defaults_to_ok_json_when_no_adapters_available
    simulate_no_adapters do
      clear_default_adapter_warning

      capture_stderr { assert_equal :ok_json, MultiJson.default_adapter }
    end
  end

  def test_finds_installable_adapter_when_none_preloaded
    # Undefine adapter constants so loaded_adapter returns nil,
    # but keep REQUIREMENT_MAP intact so installable_adapter can require them
    undefine_constants(:JSON, :Oj, :Yajl, :Gson, :JrJackson, :FastJsonparser) do
      clear_default_adapter_warning

      # This will trigger installable_adapter since no constants are defined
      adapter = capture_stderr { MultiJson.default_adapter }

      # Should find the first installable adapter from REQUIREMENT_MAP
      assert_includes %i[fast_jsonparser oj yajl jr_jackson json_gem gson], adapter
    end
  end

  def test_prints_warning_when_no_adapters_available
    simulate_no_adapters { assert_warns_about_no_adapters(times: 1) }
  end

  def test_warns_only_once_when_no_adapters_available
    simulate_no_adapters { assert_warns_about_no_adapters(times: 1) { MultiJson.default_adapter } }
  end

  def test_fallback_adapter_skips_warning_when_already_shown
    simulate_no_adapters do
      clear_default_adapter_warning

      # First call - shows warning and sets @default_adapter_warning_shown
      capture_stderr { MultiJson.default_adapter }

      # Clear @default_adapter but keep @default_adapter_warning_shown
      MultiJson.remove_instance_variable(:@default_adapter) if MultiJson.instance_variable_defined?(:@default_adapter)

      # Second call should NOT warn (exercises else branch at line 17)
      warn_count = 0
      with_stub(Kernel, :warn, ->(msg) { warn_count += 1 if /warning/i.match?(msg) }) do
        MultiJson.default_adapter
      end

      assert_equal 0, warn_count
    end
  end

  def test_busts_caches_on_global_options_change
    MultiJson.use MultiJson::Adapters::JsonGem
    assert_cache_busting { |val| MultiJson.load_options = val }
  end

  def test_busts_caches_on_per_adapter_options_change
    adapter = MultiJson::Adapters::JsonGem
    MultiJson.use adapter
    assert_cache_busting { |val| adapter.load_options = val }
  end

  def test_one_shot_parser_uses_defined_parser_for_call
    MultiJson.use :json_gem

    assert_one_shot_adapter_behavior
  end

  def test_json_gem_does_not_create_symbols_on_parse
    MultiJson.with_engine(:json_gem) do
      MultiJson.load('{"json_class":"ZOMG"}')
      original_count = Symbol.all_symbols.count
      MultiJson.load('{"json_class":"OMG"}')

      assert_equal original_count, Symbol.all_symbols.count
    end
  end

  private

  def assert_warns_about_no_adapters(times:)
    clear_default_adapter_warning
    warn_count = 0
    with_stub(Kernel, :warn, ->(msg) { warn_count += 1 if /warning/i.match?(msg) }) do
      MultiJson.default_adapter
      yield if block_given?
    end

    assert_equal times, warn_count
  end

  def assert_cache_busting
    json_string = '{"abc":"def"}'
    yield({symbolize_keys: true})

    assert_equal({abc: "def"}, MultiJson.load(json_string))
    yield(nil)

    assert_equal({"abc" => "def"}, MultiJson.load(json_string))
  end

  def assert_one_shot_adapter_behavior
    results = track_ok_json_calls { verify_one_shot_dump_and_load }

    assert results[:dump_called] && results[:load_called]
    assert_equal MultiJson::Adapters::JsonGem, MultiJson.adapter
  end

  def track_ok_json_calls(&block)
    results = {dump_called: false, load_called: false}
    dump_stub = ->(*) { (results[:dump_called] = true) && "dump_something" }
    load_stub = ->(*) { (results[:load_called] = true) && "load_something" }
    with_stub(MultiJson::Adapters::OkJson, :dump, dump_stub) do
      with_stub(MultiJson::Adapters::OkJson, :load, load_stub, &block)
    end
    results
  end

  def verify_one_shot_dump_and_load
    assert_equal "dump_something", MultiJson.dump("", adapter: :ok_json)
    assert_equal "load_something", MultiJson.load("", adapter: :ok_json)
  end
end

class MultiJsonOptionsTest < Minitest::Test
  cover "MultiJson*"

  include OptionsTests

  def subject
    MultiJson
  end
end

class MultiJsonDeprecatedMethodsTest < Minitest::Test
  cover "MultiJson*"

  def test_default_options_setter_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJson.default_options = {foo: "bar"} }
    end

    assert warned
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJson.default_options }
    end

    assert warned
  end

  def test_cached_options_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJson.cached_options }
    end

    assert warned
  end

  def test_reset_cached_options_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJson.reset_cached_options! }
    end

    assert warned
  end

  def test_default_options_setter_sets_load_options
    silence_warnings { MultiJson.default_options = {test: "value"} }

    assert_equal({test: "value"}, MultiJson.load_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_sets_dump_options
    silence_warnings { MultiJson.default_options = {test: "value"} }

    assert_equal({test: "value"}, MultiJson.dump_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_returns_load_options
    MultiJson.load_options = {specific: "value"}

    result = silence_warnings { MultiJson.default_options }

    assert_equal({specific: "value"}, result)
  ensure
    MultiJson.load_options = nil
  end
end

# Mutation-killing tests for deprecated warning behavior
class MultiJsonDeprecatedWarningMutationTest < Minitest::Test
  cover "MultiJson*"

  def test_default_options_setter_calls_kernel_warn
    warn_called = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_called = true } }

    MultiJson.default_options = {}

    assert warn_called
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_calls_kernel_warn
    warn_called = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_called = true } }

    MultiJson.default_options

    assert warn_called
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_cached_options_calls_kernel_warn
    warn_called = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_called = true } }

    MultiJson.cached_options

    assert warn_called
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_reset_cached_options_calls_kernel_warn
    warn_called = false
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |_msg| warn_called = true } }

    MultiJson.reset_cached_options!

    assert warn_called
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_cached_options_warning_includes_method_name
    warning_message = nil
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |msg| warning_message = msg } }

    MultiJson.cached_options

    assert_includes warning_message, "cached_options"
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end

  def test_reset_cached_options_warning_includes_method_name
    warning_message = nil
    original_warn = Kernel.method(:warn)

    silence_warnings { Kernel.define_singleton_method(:warn) { |msg| warning_message = msg } }

    MultiJson.reset_cached_options!

    assert_includes warning_message, "reset_cached_options!"
  ensure
    silence_warnings { Kernel.define_singleton_method(:warn, original_warn) }
  end
end

# Mutation-killing tests for default_options assignment chain
class MultiJsonDefaultOptionsAssignmentTest < Minitest::Test
  cover "MultiJson*"

  def test_default_options_setter_sets_load_options_specifically
    MultiJson.load_options = nil
    MultiJson.dump_options = nil

    silence_warnings { MultiJson.default_options = {test_load: true} }

    assert_equal({test_load: true}, MultiJson.load_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_sets_dump_options_specifically
    MultiJson.load_options = nil
    MultiJson.dump_options = nil

    silence_warnings { MultiJson.default_options = {test_dump: true} }

    assert_equal({test_dump: true}, MultiJson.dump_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_sets_both_to_same_value
    MultiJson.load_options = {old_load: true}
    MultiJson.dump_options = {old_dump: true}

    silence_warnings { MultiJson.default_options = {new_value: true} }

    assert_equal({new_value: true}, MultiJson.load_options)
    assert_equal({new_value: true}, MultiJson.dump_options)
    assert_equal MultiJson.load_options, MultiJson.dump_options
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_uses_passed_value_not_nil
    silence_warnings { MultiJson.default_options = {specific: "value"} }

    refute_nil MultiJson.load_options[:specific]
    assert_equal "value", MultiJson.load_options[:specific]
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_body_executes
    MultiJson.load_options = {before: true}
    MultiJson.dump_options = {before: true}

    silence_warnings { MultiJson.default_options = {after: true} }

    assert_equal({after: true}, MultiJson.load_options)
    assert_equal({after: true}, MultiJson.dump_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_body_executes
    MultiJson.load_options = {getter_test: "value"}

    result = silence_warnings { MultiJson.default_options }

    refute_nil result
    assert_equal({getter_test: "value"}, result)
  ensure
    MultiJson.load_options = nil
  end

  def test_default_options_getter_returns_load_options_not_dump_options
    MultiJson.load_options = {load: true}
    MultiJson.dump_options = {dump: true}

    result = silence_warnings { MultiJson.default_options }

    assert_equal({load: true}, result)
    refute_equal({dump: true}, result)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end
end

class MultiJsonErrorsTest < Minitest::Test
  cover "MultiJson*"

  def test_adapter_error_without_cause
    error = MultiJson::AdapterError.new("test message")

    assert_equal "test message", error.message
    assert_nil error.backtrace
  end

  def test_adapter_error_with_cause
    cause = StandardError.new("original")
    cause.set_backtrace(%w[line1 line2])
    error = MultiJson::AdapterError.new("test message", cause: cause)

    assert_equal "test message", error.message
    assert_equal %w[line1 line2], error.backtrace
  end

  def test_adapter_error_build_creates_error_instance
    original = LoadError.new("cannot load such file -- bad_adapter")
    error = MultiJson::AdapterError.build(original)

    assert_instance_of MultiJson::AdapterError, error
  end

  def test_adapter_error_build_message_contains_explanation
    original = LoadError.new("cannot load such file -- bad_adapter")
    error = MultiJson::AdapterError.build(original)

    assert_includes error.message, "Did not recognize your adapter specification"
  end

  def test_adapter_error_build_message_contains_original_error
    original = LoadError.new("cannot load such file -- bad_adapter")
    error = MultiJson::AdapterError.build(original)

    assert_includes error.message, "cannot load such file -- bad_adapter"
  end

  def test_adapter_error_build_message_is_properly_formatted
    original = LoadError.new("test error")
    error = MultiJson::AdapterError.build(original)

    # Message format: "Did not recognize your adapter specification (original message)."
    assert_match(/\(.*\)\.$/, error.message)
  end

  def test_adapter_error_build_includes_original_exception_message
    original = LoadError.new("specific error message")
    error = MultiJson::AdapterError.build(original)

    assert_includes error.message, "specific error message"
  end

  def test_adapter_error_build_uses_message_method
    # Verify that .message is used in the error message
    original = LoadError.new("specific message content")
    error = MultiJson::AdapterError.build(original)

    # The message should contain the original exception's message
    assert_includes error.message, "specific message content"
  end

  def test_adapter_error_build_sets_cause_backtrace
    original = LoadError.new("error")
    original.set_backtrace(%w[frame1 frame2])
    error = MultiJson::AdapterError.build(original)

    assert_equal %w[frame1 frame2], error.backtrace
  end

  def test_parse_error_without_cause
    error = MultiJson::ParseError.new("test message", data: "{invalid}")

    assert_equal "test message", error.message
    assert_equal "{invalid}", error.data
    assert_nil error.backtrace
  end

  def test_parse_error_with_cause
    cause = StandardError.new("original")
    cause.set_backtrace(%w[line1 line2])
    error = MultiJson::ParseError.new("test message", data: "{bad}", cause: cause)

    assert_equal "test message", error.message
    assert_equal "{bad}", error.data
    assert_equal %w[line1 line2], error.backtrace
  end

  def test_parse_error_build_creates_error_with_original_message
    original = StandardError.new("unexpected token at position 5")
    error = MultiJson::ParseError.build(original, "{invalid json}")

    assert_instance_of MultiJson::ParseError, error
    assert_equal "unexpected token at position 5", error.message
    assert_equal "{invalid json}", error.data
  end

  def test_parse_error_build_sets_cause_backtrace
    original = StandardError.new("parse failed")
    original.set_backtrace(%w[parse_frame1 parse_frame2])
    error = MultiJson::ParseError.build(original, "bad data")

    assert_equal %w[parse_frame1 parse_frame2], error.backtrace
  end

  def test_decode_error_is_alias_for_parse_error
    assert_equal MultiJson::ParseError, MultiJson::DecodeError
  end

  def test_load_error_is_alias_for_parse_error
    assert_equal MultiJson::ParseError, MultiJson::LoadError
  end
end

class MultiJsonAdapterDetectionTest < Minitest::Test
  cover "MultiJson*"

  include MultiJsonTestSetup

  def test_loaded_adapter_detects_oj
    skip unless defined?(::Oj)
    undefine_constants(:FastJsonparser) do
      clear_default_adapter_warning
      adapter = capture_stderr { MultiJson.default_adapter }

      assert_equal :oj, adapter
    end
  end

  def test_loaded_adapter_detects_yajl
    skip unless defined?(::Yajl)
    undefine_constants(:FastJsonparser, :Oj) do
      clear_default_adapter_warning
      adapter = capture_stderr { MultiJson.default_adapter }

      assert_equal :yajl, adapter
    end
  end

  def test_loaded_adapter_detects_json_gem
    skip unless defined?(::JSON::Ext::Parser)
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      clear_default_adapter_warning
      adapter = capture_stderr { MultiJson.default_adapter }

      assert_equal :json_gem, adapter
    end
  end

  def test_loaded_adapter_detects_jr_jackson
    undefine_constants(:FastJsonparser, :Oj, :Yajl) do
      with_temporary_constant(:JrJackson) do
        clear_default_adapter_warning
        adapter = capture_stderr { MultiJson.default_adapter }

        assert_equal :jr_jackson, adapter
      end
    end
  end

  def test_loaded_adapter_detects_gson
    undefine_constants(:FastJsonparser, :Oj, :Yajl, :JrJackson) do
      with_json_ext_parser_removed do
        with_temporary_constant(:Gson) do
          clear_default_adapter_warning
          adapter = capture_stderr { MultiJson.default_adapter }

          assert_equal :gson, adapter
        end
      end
    end
  end

  private

  def with_temporary_constant(name)
    Object.const_set(name, Module.new)
    yield
  ensure
    Object.send(:remove_const, name) if Object.const_defined?(name)
  end

  def with_json_ext_parser_removed
    json_ext_parser = defined?(::JSON::Ext::Parser) ? ::JSON::Ext::Parser : nil
    JSON::Ext.send(:remove_const, :Parser) if json_ext_parser
    yield
  ensure
    JSON::Ext.const_set(:Parser, json_ext_parser) if json_ext_parser && !defined?(::JSON::Ext::Parser)
  end
end

if TestHelpers.jrjackson?
  class MultiJsonJrJacksonAliasTest < Minitest::Test
    def test_allows_jrjackson_alias_as_symbol
      MultiJson.use :jrjackson

      assert_equal MultiJson::Adapters::JrJackson, MultiJson.adapter
    end

    def test_allows_jrjackson_alias_as_string
      MultiJson.use "jrjackson"

      assert_equal MultiJson::Adapters::JrJackson, MultiJson.adapter
    end
  end
end
