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

  def test_load_options_setter_raises_for_non_hash_values
    [true, false, 10, Object.new, "str", -> { {} }].each do |val|
      error = assert_raises(ArgumentError) { @test_class.parse_options = val }
      assert_includes error.message, "Hash or nil"
      assert_includes error.message, val.class.to_s
    end
  end

  def test_dump_options_setter_raises_for_non_hash_values
    [true, false, 10, Object.new, "str", -> { {} }].each do |val|
      error = assert_raises(ArgumentError) { @test_class.generate_options = val }
      assert_includes error.message, "Hash or nil"
      assert_includes error.message, val.class.to_s
    end
  end

  def test_load_options_setter_accepts_nil
    @test_class.parse_options = {foo: :bar}
    @test_class.parse_options = nil

    assert_empty @test_class.parse_options
  end

  def test_dump_options_setter_accepts_nil
    @test_class.generate_options = {foo: :bar}
    @test_class.generate_options = nil

    assert_empty @test_class.generate_options
  end

  def test_load_options_setter_accepts_hash_subclass
    hash_subclass = Class.new(Hash)
    instance = hash_subclass[foo: :bar]
    @test_class.parse_options = instance

    assert_equal({foo: :bar}, @test_class.parse_options)
  end

  def test_dump_options_setter_accepts_hash_subclass
    hash_subclass = Class.new(Hash)
    instance = hash_subclass[pretty: true]
    @test_class.generate_options = instance

    assert_equal({pretty: true}, @test_class.generate_options)
  end
end
