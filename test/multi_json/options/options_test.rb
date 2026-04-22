# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/options"

class OptionsTest < Minitest::Test
  cover "MultiJSON::Options*"

  def setup
    @test_class = Class.new { extend MultiJSON::Options }
  end

  def teardown
    @test_class.parse_options = nil
    @test_class.generate_options = nil
  end

  def test_load_options_returns_empty_hash_by_default
    assert_empty(@test_class.parse_options)
  end

  def test_dump_options_returns_empty_hash_by_default
    assert_empty(@test_class.generate_options)
  end

  def test_default_load_options_returns_frozen_empty_hash
    result = @test_class.default_parse_options

    assert_empty(result)
    assert_predicate result, :frozen?
  end

  def test_default_dump_options_returns_frozen_empty_hash
    result = @test_class.default_generate_options

    assert_empty(result)
    assert_predicate result, :frozen?
  end

  def test_load_options_setter_stores_options
    @test_class.parse_options = {symbolize_names: true}

    assert_equal({symbolize_names: true}, @test_class.parse_options)
  end

  def test_dump_options_setter_stores_options
    @test_class.generate_options = {pretty: true}

    assert_equal({pretty: true}, @test_class.generate_options)
  end

  def test_load_options_setter_resets_cache
    MultiJSON::OptionsCache.dump.fetch(:test_key) { "test_value" }

    @test_class.parse_options = {foo: :bar}

    assert_nil MultiJSON::OptionsCache.dump.fetch(:test_key, nil)
  end

  def test_dump_options_setter_resets_cache
    MultiJSON::OptionsCache.load.fetch(:test_key) { "test_value" }

    @test_class.generate_options = {foo: :bar}

    assert_nil MultiJSON::OptionsCache.load.fetch(:test_key, nil)
  end

  def test_load_options_with_callable_zero_arity
    @test_class.parse_options = -> { {symbolize_names: true} }

    assert_equal({symbolize_names: true}, @test_class.parse_options)
  end

  def test_dump_options_with_callable_zero_arity
    @test_class.generate_options = -> { {pretty: true} }

    assert_equal({pretty: true}, @test_class.generate_options)
  end

  def test_load_options_with_callable_with_arity
    @test_class.parse_options = ->(opts) { opts.merge(symbolize_names: true) }

    result = @test_class.parse_options({mode: :strict})

    assert_equal({mode: :strict, symbolize_names: true}, result)
  end

  def test_dump_options_with_callable_with_arity
    @test_class.generate_options = ->(opts) { opts.merge(pretty: true) }

    result = @test_class.generate_options({escape_mode: :json})

    assert_equal({escape_mode: :json, pretty: true}, result)
  end

  def test_load_options_with_to_hash_object
    options_obj = Object.new
    def options_obj.to_hash = {symbolize_names: true}

    @test_class.parse_options = options_obj

    assert_equal({symbolize_names: true}, @test_class.parse_options)
  end

  def test_dump_options_with_to_hash_object
    options_obj = Object.new
    def options_obj.to_hash = {pretty: true}

    @test_class.generate_options = options_obj

    assert_equal({pretty: true}, @test_class.generate_options)
  end

  def test_load_options_with_non_hashable_returns_default
    @test_class.parse_options = "not a hash"

    assert_empty(@test_class.parse_options)
  end

  def test_dump_options_with_non_hashable_returns_default
    @test_class.generate_options = "not a hash"

    assert_empty(@test_class.generate_options)
  end

  def test_load_options_callable_receives_arguments
    received_args = nil
    @test_class.parse_options = lambda { |*args|
      received_args = args
      {}
    }

    @test_class.parse_options({foo: :bar}, :extra)

    assert_equal [{foo: :bar}, :extra], received_args
  end
end
