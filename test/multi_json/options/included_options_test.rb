require_relative "../../test_helper"
require "multi_json/options"

# Tests for Options via instance methods (using include)
class IncludedOptionsTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { include MultiJson::Options }
    @instance = @test_class.new
  end

  def teardown
    @instance.load_options = nil
    @instance.dump_options = nil
  end

  def test_instance_load_options_returns_default_when_undefined
    @instance.remove_instance_variable(:@load_options) if @instance.instance_variable_defined?(:@load_options)

    result = @instance.load_options

    assert_equal @instance.default_load_options, result
  end

  def test_instance_dump_options_returns_default_when_undefined
    @instance.remove_instance_variable(:@dump_options) if @instance.instance_variable_defined?(:@dump_options)

    result = @instance.dump_options

    assert_equal @instance.default_dump_options, result
  end

  def test_instance_load_options_returns_options_when_defined
    @instance.load_options = {defined_test: true}

    result = @instance.load_options

    assert_equal({defined_test: true}, result)
  end

  def test_instance_dump_options_returns_options_when_defined
    @instance.dump_options = {defined_test: true}

    result = @instance.dump_options

    assert_equal({defined_test: true}, result)
  end

  def test_instance_defined_check_short_circuits_when_undefined
    @instance.remove_instance_variable(:@load_options) if @instance.instance_variable_defined?(:@load_options)

    result = @instance.load_options

    assert_equal @instance.default_load_options, result
    assert_empty result
  end

  def test_instance_defined_check_passes_to_get_options_when_defined
    @instance.load_options = {test: "value"}

    result = @instance.load_options

    assert_equal "value", result[:test]
  end

  def test_instance_handle_hashable_returns_nil_else_branch
    @instance.load_options = "not_hashable_object"

    result = @instance.load_options

    # Should return default, not crash
    assert_equal @instance.default_load_options, result
  end

  def test_instance_handle_hashable_else_nil_enables_default_fallback
    non_hashable = Object.new
    @instance.load_options = non_hashable

    result = @instance.load_options

    # nil from handle_hashable_options triggers || default_load_options
    assert_equal @instance.default_load_options, result
  end
end
