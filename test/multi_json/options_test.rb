require_relative "../test_helper"
require "multi_json/options"

class OptionsTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { extend MultiJson::Options }
  end

  def teardown
    @test_class.load_options = nil
    @test_class.dump_options = nil
  end

  def test_load_options_returns_empty_hash_by_default
    assert_empty(@test_class.load_options)
  end

  def test_dump_options_returns_empty_hash_by_default
    assert_empty(@test_class.dump_options)
  end

  def test_default_load_options_returns_frozen_empty_hash
    result = @test_class.default_load_options

    assert_empty(result)
    assert_predicate result, :frozen?
  end

  def test_default_dump_options_returns_frozen_empty_hash
    result = @test_class.default_dump_options

    assert_empty(result)
    assert_predicate result, :frozen?
  end

  def test_load_options_setter_stores_options
    @test_class.load_options = {symbolize_keys: true}

    assert_equal({symbolize_keys: true}, @test_class.load_options)
  end

  def test_dump_options_setter_stores_options
    @test_class.dump_options = {pretty: true}

    assert_equal({pretty: true}, @test_class.dump_options)
  end

  def test_load_options_setter_resets_cache
    MultiJson::OptionsCache.dump.fetch(:test_key) { "test_value" }

    @test_class.load_options = {foo: :bar}

    assert_nil MultiJson::OptionsCache.dump.fetch(:test_key, nil)
  end

  def test_dump_options_setter_resets_cache
    MultiJson::OptionsCache.load.fetch(:test_key) { "test_value" }

    @test_class.dump_options = {foo: :bar}

    assert_nil MultiJson::OptionsCache.load.fetch(:test_key, nil)
  end

  def test_load_options_with_callable_zero_arity
    @test_class.load_options = -> { {symbolize_keys: true} }

    assert_equal({symbolize_keys: true}, @test_class.load_options)
  end

  def test_dump_options_with_callable_zero_arity
    @test_class.dump_options = -> { {pretty: true} }

    assert_equal({pretty: true}, @test_class.dump_options)
  end

  def test_load_options_with_callable_with_arity
    @test_class.load_options = ->(opts) { opts.merge(symbolize_keys: true) }

    result = @test_class.load_options({mode: :strict})

    assert_equal({mode: :strict, symbolize_keys: true}, result)
  end

  def test_dump_options_with_callable_with_arity
    @test_class.dump_options = ->(opts) { opts.merge(pretty: true) }

    result = @test_class.dump_options({escape_mode: :json})

    assert_equal({escape_mode: :json, pretty: true}, result)
  end

  def test_load_options_with_to_hash_object
    options_obj = Object.new
    def options_obj.to_hash = {symbolize_keys: true}

    @test_class.load_options = options_obj

    assert_equal({symbolize_keys: true}, @test_class.load_options)
  end

  def test_dump_options_with_to_hash_object
    options_obj = Object.new
    def options_obj.to_hash = {pretty: true}

    @test_class.dump_options = options_obj

    assert_equal({pretty: true}, @test_class.dump_options)
  end

  def test_load_options_with_non_hashable_returns_default
    @test_class.load_options = "not a hash"

    assert_empty(@test_class.load_options)
  end

  def test_dump_options_with_non_hashable_returns_default
    @test_class.dump_options = "not a hash"

    assert_empty(@test_class.dump_options)
  end

  def test_load_options_callable_receives_arguments
    received_args = nil
    @test_class.load_options = lambda { |*args|
      received_args = args
      {}
    }

    @test_class.load_options({foo: :bar}, :extra)

    assert_equal [{foo: :bar}, :extra], received_args
  end
end

# Basic mutation-killing tests for Options module
class OptionsBasicMutationTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { extend MultiJson::Options }
  end

  def teardown
    @test_class.load_options = nil
    @test_class.dump_options = nil
  end

  def test_load_options_returns_result_of_get_options
    @test_class.load_options = {specific: "value"}

    result = @test_class.load_options

    assert_equal "value", result[:specific]
  end

  def test_dump_options_returns_result_of_get_options
    @test_class.dump_options = {specific: "value"}

    result = @test_class.dump_options

    assert_equal "value", result[:specific]
  end

  def test_callable_zero_arity_calls_without_args
    call_count = 0
    @test_class.load_options = lambda {
      call_count += 1
      {}
    }

    @test_class.load_options

    assert_equal 1, call_count
  end

  def test_callable_with_arity_calls_with_args
    received = nil
    @test_class.load_options = lambda { |arg|
      received = arg
      {}
    }

    @test_class.load_options({test: true})

    assert_equal({test: true}, received)
  end

  def test_callable_zero_arity_ignores_passed_arguments
    zero_arity_called = false
    @test_class.load_options = lambda {
      zero_arity_called = true
      {from: :zero}
    }
    result = @test_class.load_options({ignored: true})

    assert zero_arity_called
    assert_equal({from: :zero}, result)
  end

  def test_callable_nonzero_arity_receives_arguments
    @test_class.load_options = ->(opts) { {from: :nonzero, got: opts} }
    result = @test_class.load_options({passed: true})

    assert_equal :nonzero, result[:from]
    assert_equal({passed: true}, result[:got])
  end

  def test_options_callable_check_uses_respond_to_call
    callable = Object.new
    def callable.call = {from_callable: true}
    def callable.arity = 0

    @test_class.load_options = callable

    assert_equal({from_callable: true}, @test_class.load_options)
  end

  def test_hashable_options_uses_to_hash
    hashable = Object.new
    def hashable.to_hash = {from_to_hash: true}

    @test_class.load_options = hashable

    assert_equal({from_to_hash: true}, @test_class.load_options)
  end

  def test_non_hashable_non_callable_returns_nil_then_default
    @test_class.load_options = "string without to_hash"

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_default_options_memoization
    first_call = @test_class.default_load_options
    second_call = @test_class.default_load_options

    assert_same first_call, second_call
  end

  def test_setter_stores_exact_value
    options = {exact: "value"}
    @test_class.load_options = options

    assert_equal "value", @test_class.load_options[:exact]
  end

  def test_dump_options_callable_receives_arguments
    received_args = nil
    @test_class.dump_options = lambda { |*args|
      received_args = args
      {}
    }

    @test_class.dump_options({foo: :bar}, :extra)

    assert_equal [{foo: :bar}, :extra], received_args
  end
end

# Tests for cache reset behavior
class OptionsCacheResetTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { extend MultiJson::Options }
  end

  def teardown
    @test_class.load_options = nil
    @test_class.dump_options = nil
  end

  def test_load_options_setter_resets_cache_before_assignment
    reset_called = track_cache_reset { @test_class.load_options = {test: true} }

    assert reset_called
  end

  def test_dump_options_setter_resets_cache_before_assignment
    reset_called = track_cache_reset { @test_class.dump_options = {test: true} }

    assert reset_called
  end

  def test_load_options_stores_value_in_instance_variable
    @test_class.load_options = {stored: "value"}

    assert_equal({stored: "value"}, @test_class.instance_variable_get(:@load_options))
  end

  def test_dump_options_stores_value_in_instance_variable
    @test_class.dump_options = {stored: "value"}

    assert_equal({stored: "value"}, @test_class.instance_variable_get(:@dump_options))
  end

  private

  def track_cache_reset
    reset_called = false
    original_reset = MultiJson::OptionsCache.method(:reset)

    silence_warnings do
      MultiJson::OptionsCache.define_singleton_method(:reset) { reset_called = original_reset.call }
    end

    yield
    reset_called
  ensure
    silence_warnings { MultiJson::OptionsCache.define_singleton_method(:reset, original_reset) }
  end
end

# Tests for get_options return behavior
class OptionsGetOptionsTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { extend MultiJson::Options }
  end

  def teardown
    @test_class.load_options = nil
    @test_class.dump_options = nil
  end

  def test_get_options_returns_callable_result
    @test_class.load_options = -> { {from_callable: true} }

    result = @test_class.load_options

    assert_equal({from_callable: true}, result)
  end

  def test_get_options_returns_hashable_result
    hashable = Object.new
    def hashable.to_hash = {from_hash: true}

    @test_class.load_options = hashable

    assert_equal({from_hash: true}, @test_class.load_options)
  end

  def test_options_custom_callable_object_uses_respond_to_call
    callable = Object.new
    def callable.call = {custom_call: true}
    def callable.arity = 0

    @test_class.load_options = callable

    assert_equal({custom_call: true}, @test_class.load_options)
  end

  def test_handle_callable_options_checks_arity
    zero_arity = -> { {zero: true} }
    @test_class.load_options = zero_arity

    result = @test_class.load_options({ignored: true})

    assert_equal({zero: true}, result)
  end

  def test_handle_callable_options_with_arity_calls_with_args
    with_arity = ->(opts) { opts.merge(added: true) }
    @test_class.load_options = with_arity

    result = @test_class.load_options({original: true})

    assert_equal({original: true, added: true}, result)
  end

  def test_handle_hashable_options_returns_to_hash
    hashable = Object.new
    def hashable.to_hash = {converted: true}

    @test_class.load_options = hashable

    assert_equal({converted: true}, @test_class.load_options)
  end

  def test_handle_hashable_options_returns_nil_for_non_hashable
    @test_class.load_options = "not hashable"

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end
end

# Tests for default options behavior
class OptionsDefaultOptionsTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { extend MultiJson::Options }
  end

  def teardown
    @test_class.load_options = nil
    @test_class.dump_options = nil
  end

  def test_default_load_options_returns_frozen_empty_hash
    result = @test_class.default_load_options

    assert_empty result
    assert_predicate result, :frozen?
  end

  def test_default_dump_options_returns_frozen_empty_hash
    result = @test_class.default_dump_options

    assert_empty result
    assert_predicate result, :frozen?
  end

  def test_default_options_are_memoized
    first = @test_class.default_load_options
    second = @test_class.default_load_options

    assert_same first, second
  end

  def test_load_options_with_undefined_returns_default
    @test_class.remove_instance_variable(:@load_options) if @test_class.instance_variable_defined?(:@load_options)

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_dump_options_with_undefined_returns_default
    @test_class.remove_instance_variable(:@dump_options) if @test_class.instance_variable_defined?(:@dump_options)

    result = @test_class.dump_options

    assert_equal @test_class.default_dump_options, result
  end
end

# Tests for defined? check behavior
class OptionsDefinedCheckTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { extend MultiJson::Options }
  end

  def teardown
    @test_class.load_options = nil
    @test_class.dump_options = nil
  end

  def test_load_options_checks_defined_before_get_options
    @test_class.remove_instance_variable(:@load_options) if @test_class.instance_variable_defined?(:@load_options)

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_dump_options_checks_defined_before_get_options
    @test_class.remove_instance_variable(:@dump_options) if @test_class.instance_variable_defined?(:@dump_options)

    result = @test_class.dump_options

    assert_equal @test_class.default_dump_options, result
  end

  def test_handle_hashable_returns_nil_for_non_hashable
    @test_class.load_options = 12_345

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_handle_hashable_nil_enables_fallback_to_default
    @test_class.load_options = Object.new

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_load_options_returns_get_options_result_when_defined
    @test_class.load_options = {defined: true}

    result = @test_class.load_options

    assert_equal({defined: true}, result)
  end

  def test_dump_options_returns_get_options_result_when_defined
    @test_class.dump_options = {defined: true}

    result = @test_class.dump_options

    assert_equal({defined: true}, result)
  end

  def test_get_options_nil_result_falls_back_to_default
    non_hashable = Object.new
    @test_class.load_options = non_hashable

    result = @test_class.load_options

    assert_empty result
  end
end
