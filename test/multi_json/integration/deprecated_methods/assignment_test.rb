require_relative "../../../test_helper"

# Tests for default_options assignment chain
class DefaultOptionsAssignmentTest < Minitest::Test
  cover "MultiJson*"

  def test_default_options_setter_sets_load_options_specifically
    MultiJson.load_options = nil
    MultiJson.dump_options = nil

    silence_warnings { MultiJson.default_options = {test_load: true} }

    assert_equal({test_load: true}, MultiJson.load_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_sets_dump_options_specifically
    MultiJson.load_options = nil
    MultiJson.dump_options = nil

    silence_warnings { MultiJson.default_options = {test_dump: true} }

    assert_equal({test_dump: true}, MultiJson.dump_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_sets_both_to_same_value
    MultiJson.load_options = {old_load: true}
    MultiJson.dump_options = {old_dump: true}

    silence_warnings { MultiJson.default_options = {new_value: true} }

    assert_equal({new_value: true}, MultiJson.load_options)
    assert_equal({new_value: true}, MultiJson.dump_options)
    assert_equal MultiJson.load_options, MultiJson.dump_options
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_uses_passed_value_not_nil
    silence_warnings { MultiJson.default_options = {specific: "value"} }

    refute_nil MultiJson.load_options[:specific]
    assert_equal "value", MultiJson.load_options[:specific]
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_setter_body_executes
    MultiJson.load_options = {before: true}
    MultiJson.dump_options = {before: true}

    silence_warnings { MultiJson.default_options = {after: true} }

    assert_equal({after: true}, MultiJson.load_options)
    assert_equal({after: true}, MultiJson.dump_options)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end

  def test_default_options_getter_body_executes
    MultiJson.load_options = {getter_test: "value"}

    result = silence_warnings { MultiJson.default_options }

    refute_nil result
    assert_equal({getter_test: "value"}, result)
  ensure
    MultiJson.load_options = nil
  end

  def test_default_options_getter_returns_load_options_not_dump_options
    MultiJson.load_options = {load: true}
    MultiJson.dump_options = {dump: true}

    result = silence_warnings { MultiJson.default_options }

    assert_equal({load: true}, result)
    refute_equal({dump: true}, result)
  ensure
    MultiJson.load_options = MultiJson.dump_options = nil
  end
end
