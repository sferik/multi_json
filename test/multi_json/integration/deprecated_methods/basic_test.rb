# frozen_string_literal: true

require_relative "../../../test_helper"

class DeprecatedMethodsTest < Minitest::Test
  cover "MultiJSON*"

  def setup
    MultiJSON.send(:const_get, :DEPRECATION_WARNINGS_SHOWN).clear
  end

  def test_default_options_setter_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg, **) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJSON.default_options = {foo: "bar"} }
    end

    assert warned
  ensure
    MultiJSON.parse_options = MultiJSON.generate_options = nil
  end

  def test_default_options_getter_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg, **) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJSON.default_options }
    end

    assert warned
  end

  def test_cached_options_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg, **) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJSON.cached_options }
    end

    assert warned
  end

  def test_reset_cached_options_is_deprecated
    warned = false
    with_stub(Kernel, :warn, ->(msg, **) { warned = true if /deprecated/i.match?(msg) }) do
      silence_warnings { MultiJSON.reset_cached_options! }
    end

    assert warned
  end

  def test_default_options_setter_sets_load_options
    silence_warnings { MultiJSON.default_options = {test: "value"} }

    assert_equal({test: "value"}, MultiJSON.load_options)
  ensure
    MultiJSON.parse_options = MultiJSON.generate_options = nil
  end

  def test_default_options_setter_sets_dump_options
    silence_warnings { MultiJSON.default_options = {test: "value"} }

    assert_equal({test: "value"}, MultiJSON.dump_options)
  ensure
    MultiJSON.parse_options = MultiJSON.generate_options = nil
  end

  def test_default_options_getter_returns_load_options
    MultiJSON.load_options = {specific: "value"}

    result = silence_warnings { MultiJSON.default_options }

    assert_equal({specific: "value"}, result)
  ensure
    MultiJSON.load_options = nil
  end
end
