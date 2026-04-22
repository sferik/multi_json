# frozen_string_literal: true

require_relative "../../test_helper"
require "multi_json/options"

# Tests for Options via instance methods (using include)
class IncludedOptionsTest < Minitest::Test
  cover "MultiJSON::Options*"

  def setup
    @test_class = Class.new { include MultiJSON::Options }
    @instance = @test_class.new
  end

  def teardown
    @instance.parse_options = nil
    @instance.generate_options = nil
  end

  def test_instance_load_options_returns_default_when_undefined
    @instance.remove_instance_variable(:@load_options) if @instance.instance_variable_defined?(:@load_options)

    result = @instance.parse_options

    assert_equal @instance.default_parse_options, result
  end

  def test_instance_dump_options_returns_default_when_undefined
    @instance.remove_instance_variable(:@dump_options) if @instance.instance_variable_defined?(:@dump_options)

    result = @instance.generate_options

    assert_equal @instance.default_generate_options, result
  end

  def test_instance_load_options_returns_options_when_defined
    @instance.parse_options = {defined_test: true}

    result = @instance.parse_options

    assert_equal({defined_test: true}, result)
  end

  def test_instance_dump_options_returns_options_when_defined
    @instance.generate_options = {defined_test: true}

    result = @instance.generate_options

    assert_equal({defined_test: true}, result)
  end

  def test_instance_defined_check_short_circuits_when_undefined
    @instance.remove_instance_variable(:@load_options) if @instance.instance_variable_defined?(:@load_options)

    result = @instance.parse_options

    assert_equal @instance.default_parse_options, result
    assert_empty result
  end

  def test_instance_defined_check_passes_to_get_options_when_defined
    @instance.parse_options = {test: "value"}

    result = @instance.parse_options

    assert_equal "value", result[:test]
  end

  def test_instance_handle_hashable_returns_nil_else_branch
    @instance.parse_options = "not_hashable_object"

    result = @instance.parse_options

    # Should return default, not crash
    assert_equal @instance.default_parse_options, result
  end

  def test_instance_handle_hashable_else_nil_enables_default_fallback
    non_hashable = Object.new
    @instance.parse_options = non_hashable

    result = @instance.parse_options

    # nil from handle_hashable_options triggers || default_load_options
    assert_equal @instance.default_parse_options, result
  end
end
