# frozen_string_literal: true

require_relative "../../test_helper"

class DeprecatedOptionsTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).clear
  end

  def test_default_options_setter_sets_both_load_and_dump_options
    silence_warnings do
      MultiJSON.default_options = {foo: "bar"}
    end

    assert_equal({foo: "bar"}, MultiJSON.load_options)
    assert_equal({foo: "bar"}, MultiJSON.dump_options)
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  def test_default_options_getter_returns_load_options
    MultiJSON.load_options = {test: "value"}

    result = silence_warnings { MultiJSON.default_options }

    assert_equal({test: "value"}, result)
  ensure
    MultiJSON.load_options = nil
  end

  def test_default_options_instance_method_returns_load_options
    MultiJSON.load_options = {test: "value"}
    object = Class.new { include MultiJSON }.new
    object.define_singleton_method(:load_options) { MultiJSON.load_options }

    result = silence_warnings { object.send(:default_options) }

    assert_equal({test: "value"}, result)
  ensure
    MultiJSON.load_options = nil
  end

  def test_default_options_instance_method_warns
    object = Class.new { include MultiJSON }.new
    object.define_singleton_method(:load_options) { MultiJSON.load_options }
    warning_message = nil

    with_stub(Kernel, :warn, ->(msg) { warning_message = msg }) do
      silence_warnings { object.send(:default_options) }
    end

    refute_nil warning_message
    assert_includes warning_message, "MultiJSON.default_options"
  end

  def test_default_options_instance_setter_sets_load_and_dump_options
    object = default_options_instance

    silence_warnings { object.send(:default_options=, foo: "bar") }

    assert_equal({foo: "bar"}, MultiJSON.load_options)
    assert_equal({foo: "bar"}, MultiJSON.dump_options)
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  def test_default_options_instance_setter_warns
    object = default_options_instance
    warning_message = nil

    with_stub(Kernel, :warn, ->(msg) { warning_message = msg }) do
      silence_warnings { object.send(:default_options=, foo: "bar") }
    end

    refute_nil warning_message
    assert_includes warning_message, "MultiJSON.default_options setter"
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  private

  def default_options_instance
    Class.new { include MultiJSON }.new.tap do |object|
      object.define_singleton_method(:load_options) { MultiJSON.load_options }
      object.define_singleton_method(:load_options=) { |value| MultiJSON.load_options = value }
      object.define_singleton_method(:dump_options=) { |value| MultiJSON.dump_options = value }
    end
  end
end
