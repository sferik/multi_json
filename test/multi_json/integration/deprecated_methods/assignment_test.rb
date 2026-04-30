# frozen_string_literal: true

require_relative "../../../test_helper"

# Tests for default_options assignment chain
class DefaultOptionsAssignmentTest < Minitest::Test
  cover "MultiJSON*"

  def test_default_options_setter_sets_load_options_specifically
    MultiJSON.load_options = nil
    MultiJSON.dump_options = nil

    silence_warnings { MultiJSON.default_options = {test_load: true} }

    assert_equal({test_load: true}, MultiJSON.load_options)
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  def test_default_options_setter_sets_dump_options_specifically
    MultiJSON.load_options = nil
    MultiJSON.dump_options = nil

    silence_warnings { MultiJSON.default_options = {test_dump: true} }

    assert_equal({test_dump: true}, MultiJSON.dump_options)
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  def test_default_options_setter_sets_both_to_same_value
    MultiJSON.load_options = {old_load: true}
    MultiJSON.dump_options = {old_dump: true}

    silence_warnings { MultiJSON.default_options = {new_value: true} }

    assert_equal({new_value: true}, MultiJSON.load_options)
    assert_equal({new_value: true}, MultiJSON.dump_options)
    assert_equal MultiJSON.load_options, MultiJSON.dump_options
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  def test_default_options_setter_uses_passed_value_not_nil
    silence_warnings { MultiJSON.default_options = {specific: "value"} }

    refute_nil MultiJSON.load_options[:specific]
    assert_equal "value", MultiJSON.load_options[:specific]
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  def test_default_options_setter_body_executes
    MultiJSON.load_options = {before: true}
    MultiJSON.dump_options = {before: true}

    silence_warnings { MultiJSON.default_options = {after: true} }

    assert_equal({after: true}, MultiJSON.load_options)
    assert_equal({after: true}, MultiJSON.dump_options)
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end

  def test_default_options_getter_body_executes
    MultiJSON.load_options = {getter_test: "value"}

    result = silence_warnings { MultiJSON.default_options }

    refute_nil result
    assert_equal({getter_test: "value"}, result)
  ensure
    MultiJSON.load_options = nil
  end

  def test_default_options_getter_returns_load_options_not_dump_options
    MultiJSON.load_options = {load: true}
    MultiJSON.dump_options = {dump: true}

    result = silence_warnings { MultiJSON.default_options }

    assert_equal({load: true}, result)
    refute_equal({dump: true}, result)
  ensure
    MultiJSON.load_options = MultiJSON.dump_options = nil
  end
end
