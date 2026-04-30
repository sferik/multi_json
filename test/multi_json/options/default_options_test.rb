# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/options"

# Tests for default options behavior
class OptionsDefaultOptionsTest < Minitest::Test
  cover "MultiJSON::Options*"

  def setup
    @test_class = Class.new { extend MultiJSON::Options }
  end

  def teardown
    @test_class.parse_options = nil
    @test_class.generate_options = nil
  end

  def test_default_load_options_returns_frozen_empty_hash
    result = @test_class.default_parse_options

    assert_empty result
    assert_predicate result, :frozen?
  end

  def test_default_dump_options_returns_frozen_empty_hash
    result = @test_class.default_generate_options

    assert_empty result
    assert_predicate result, :frozen?
  end

  def test_default_options_are_memoized
    first = @test_class.default_parse_options
    second = @test_class.default_parse_options

    assert_same first, second
  end

  def test_load_options_with_undefined_returns_default
    @test_class.remove_instance_variable(:@parse_options) if @test_class.instance_variable_defined?(:@parse_options)

    result = @test_class.parse_options

    assert_equal @test_class.default_parse_options, result
  end

  def test_dump_options_with_undefined_returns_default
    @test_class.remove_instance_variable(:@generate_options) if @test_class.instance_variable_defined?(:@generate_options)

    result = @test_class.generate_options

    assert_equal @test_class.default_generate_options, result
  end

  def test_default_load_options_holds_mutex_during_init
    flag = stub_default_options_synchronize

    @test_class.default_parse_options

    assert flag.value
  ensure
    restore_default_options_synchronize
  end

  def test_default_dump_options_holds_mutex_during_init
    flag = stub_default_options_synchronize

    @test_class.default_generate_options

    assert flag.value
  ensure
    restore_default_options_synchronize
  end

  private

  def stub_default_options_synchronize
    @options_mutex = MultiJSON::Concurrency.const_get(:MUTEXES).fetch(:default_options)
    flag = Struct.new(:value).new(false)
    @options_mutex.define_singleton_method(:synchronize) do |&block|
      flag.value = true
      block.call
    end
    flag
  end

  def restore_default_options_synchronize
    @options_mutex&.singleton_class&.send(:remove_method, :synchronize)
  end
end
