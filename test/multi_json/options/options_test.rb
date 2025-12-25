require_relative "../../test_helper"
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
