require_relative "../../test_helper"
require "multi_json/options"

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
