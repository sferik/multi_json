# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/options"

# Tests for get_options return behavior
class OptionsGetOptionsTest < Minitest::Test
  cover "MultiJSON::Options*"

  def setup
    @test_class = Class.new { extend MultiJSON::Options }
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
