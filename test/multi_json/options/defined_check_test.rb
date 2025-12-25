require_relative "../../test_helper"
require "multi_json/options"

# Tests for defined? check behavior
class OptionsDefinedCheckTest < Minitest::Test
  cover "MultiJson::Options*"

  def setup
    @test_class = Class.new { extend MultiJson::Options }
  end

  def teardown
    @test_class.load_options = nil
    @test_class.dump_options = nil
  end

  def test_load_options_defined_check_returns_default_when_undefined
    @test_class.remove_instance_variable(:@load_options) if @test_class.instance_variable_defined?(:@load_options)

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_dump_options_defined_check_returns_default_when_undefined
    @test_class.remove_instance_variable(:@dump_options) if @test_class.instance_variable_defined?(:@dump_options)

    result = @test_class.dump_options

    assert_equal @test_class.default_dump_options, result
  end

  def test_load_options_defined_check_returns_options_when_defined
    @test_class.load_options = {defined_test: true}

    result = @test_class.load_options

    assert_equal({defined_test: true}, result)
    refute_equal @test_class.default_load_options, result
  end

  def test_dump_options_defined_check_returns_options_when_defined
    @test_class.dump_options = {defined_test: true}

    result = @test_class.dump_options

    assert_equal({defined_test: true}, result)
    refute_equal @test_class.default_dump_options, result
  end

  def test_load_options_checks_defined_before_get_options
    @test_class.remove_instance_variable(:@load_options) if @test_class.instance_variable_defined?(:@load_options)

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_dump_options_checks_defined_before_get_options
    @test_class.remove_instance_variable(:@dump_options) if @test_class.instance_variable_defined?(:@dump_options)

    result = @test_class.dump_options

    assert_equal @test_class.default_dump_options, result
  end

  def test_handle_hashable_returns_nil_for_non_hashable
    @test_class.load_options = 12_345

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_handle_hashable_nil_enables_fallback_to_default
    @test_class.load_options = Object.new

    result = @test_class.load_options

    assert_equal @test_class.default_load_options, result
  end

  def test_load_options_returns_get_options_result_when_defined
    @test_class.load_options = {defined: true}

    result = @test_class.load_options

    assert_equal({defined: true}, result)
  end

  def test_dump_options_returns_get_options_result_when_defined
    @test_class.dump_options = {defined: true}

    result = @test_class.dump_options

    assert_equal({defined: true}, result)
  end

  def test_get_options_nil_result_falls_back_to_default
    non_hashable = Object.new
    @test_class.load_options = non_hashable

    result = @test_class.load_options

    assert_empty result
  end

  def test_handle_hashable_calls_to_hash_method
    hashable = Object.new
    def hashable.respond_to?(method, *) = method == :to_hash || super
    def hashable.to_hash = {from_to_hash_method: true}

    @test_class.load_options = hashable

    result = @test_class.load_options

    assert_equal({from_to_hash_method: true}, result)
    refute_nil result
  end

  def test_handle_hashable_returns_to_hash_result_not_nil
    hashable = Object.new
    def hashable.respond_to?(method, *) = method == :to_hash || super
    def hashable.to_hash = {specific_key: "specific_value"}

    @test_class.load_options = hashable

    result = @test_class.load_options

    refute_nil result
    assert_equal "specific_value", result[:specific_key]
  end

  def test_handle_hashable_respects_to_hash_return_value
    unique_hash = {unique_key: "unique_value"}
    hashable = Object.new
    hashable.define_singleton_method(:to_hash) { unique_hash }

    @test_class.load_options = hashable

    result = @test_class.load_options

    assert_equal unique_hash, result
  end
end
