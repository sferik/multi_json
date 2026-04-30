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

  def test_instance_parse_options_returns_default_when_undefined
    @instance.remove_instance_variable(:@parse_options) if @instance.instance_variable_defined?(:@parse_options)

    result = @instance.parse_options

    assert_equal @instance.default_parse_options, result
  end

  def test_instance_generate_options_returns_default_when_undefined
    @instance.remove_instance_variable(:@generate_options) if @instance.instance_variable_defined?(:@generate_options)

    result = @instance.generate_options

    assert_equal @instance.default_generate_options, result
  end

  def test_instance_parse_options_returns_options_when_defined
    @instance.parse_options = {defined_test: true}

    assert_equal({defined_test: true}, @instance.parse_options)
  end

  def test_instance_generate_options_returns_options_when_defined
    @instance.generate_options = {defined_test: true}

    assert_equal({defined_test: true}, @instance.generate_options)
  end
end
