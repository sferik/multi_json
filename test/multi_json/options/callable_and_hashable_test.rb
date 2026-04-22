# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/options"

# Tests for Options module callable and hashable handling
class OptionsCallableAndHashableTest < Minitest::Test
  cover "MultiJSON::Options*"

  def setup
    @test_class = Class.new { extend MultiJSON::Options }
  end

  def teardown
    @test_class.parse_options = nil
    @test_class.generate_options = nil
  end

  def test_load_options_returns_result_of_get_options
    @test_class.parse_options = {specific: "value"}

    result = @test_class.parse_options

    assert_equal "value", result[:specific]
  end

  def test_dump_options_returns_result_of_get_options
    @test_class.generate_options = {specific: "value"}

    result = @test_class.generate_options

    assert_equal "value", result[:specific]
  end

  def test_callable_zero_arity_calls_without_args
    call_count = 0
    @test_class.parse_options = lambda {
      call_count += 1
      {}
    }

    @test_class.parse_options

    assert_equal 1, call_count
  end

  def test_callable_with_arity_calls_with_args
    received = nil
    @test_class.parse_options = lambda { |arg|
      received = arg
      {}
    }

    @test_class.parse_options({test: true})

    assert_equal({test: true}, received)
  end

  def test_callable_zero_arity_ignores_passed_arguments
    zero_arity_called = false
    @test_class.parse_options = lambda {
      zero_arity_called = true
      {from: :zero}
    }
    result = @test_class.parse_options({ignored: true})

    assert zero_arity_called
    assert_equal({from: :zero}, result)
  end

  def test_callable_nonzero_arity_receives_arguments
    @test_class.parse_options = ->(opts) { {from: :nonzero, got: opts} }
    result = @test_class.parse_options({passed: true})

    assert_equal :nonzero, result[:from]
    assert_equal({passed: true}, result[:got])
  end

  def test_options_callable_check_uses_respond_to_call
    callable = Object.new
    def callable.call = {from_callable: true}
    def callable.arity = 0

    @test_class.parse_options = callable

    assert_equal({from_callable: true}, @test_class.parse_options)
  end

  def test_hashable_options_uses_to_hash
    hashable = Object.new
    def hashable.to_hash = {from_to_hash: true}

    @test_class.parse_options = hashable

    assert_equal({from_to_hash: true}, @test_class.parse_options)
  end

  def test_non_hashable_non_callable_returns_nil_then_default
    @test_class.parse_options = "string without to_hash"

    result = @test_class.parse_options

    assert_equal @test_class.default_parse_options, result
  end

  def test_default_options_memoization
    first_call = @test_class.default_parse_options
    second_call = @test_class.default_parse_options

    assert_same first_call, second_call
  end

  def test_setter_stores_exact_value
    options = {exact: "value"}
    @test_class.parse_options = options

    assert_equal "value", @test_class.parse_options[:exact]
  end

  def test_dump_options_callable_receives_arguments
    received_args = nil
    @test_class.generate_options = lambda { |*args|
      received_args = args
      {}
    }

    @test_class.generate_options({foo: :bar}, :extra)

    assert_equal [{foo: :bar}, :extra], received_args
  end
end
