# frozen_string_literal: true

require_relative "../../test_helper"

class ErrorsIntegrationTest < Minitest::Test
  cover "MultiJson*"

  def test_adapter_error_without_cause
    error = MultiJson::AdapterError.new("test message")

    assert_equal "test message", error.message
    assert_nil error.backtrace
  end

  def test_adapter_error_with_cause
    cause = StandardError.new("original")
    cause.set_backtrace(%w[line1 line2])
    error = MultiJson::AdapterError.new("test message", cause: cause)

    assert_equal "test message", error.message
    assert_equal %w[line1 line2], error.backtrace
  end

  def test_adapter_error_build_creates_error_instance
    original = LoadError.new("cannot load such file -- bad_adapter")
    error = MultiJson::AdapterError.build(original)

    assert_instance_of MultiJson::AdapterError, error
  end

  def test_adapter_error_build_message_contains_explanation
    original = LoadError.new("cannot load such file -- bad_adapter")
    error = MultiJson::AdapterError.build(original)

    assert_includes error.message, "Did not recognize your adapter specification"
  end

  def test_adapter_error_build_message_contains_original_error
    original = LoadError.new("cannot load such file -- bad_adapter")
    error = MultiJson::AdapterError.build(original)

    assert_includes error.message, "cannot load such file -- bad_adapter"
  end

  def test_adapter_error_build_message_is_properly_formatted
    original = LoadError.new("test error")
    error = MultiJson::AdapterError.build(original)

    # Message format: "Did not recognize your adapter specification (original message)."
    assert_match(/\(.*\)\.$/, error.message)
  end

  def test_adapter_error_build_includes_original_exception_message
    original = LoadError.new("specific error message")
    error = MultiJson::AdapterError.build(original)

    assert_includes error.message, "specific error message"
  end

  def test_adapter_error_build_uses_message_method
    # Verify that .message is used in the error message
    original = LoadError.new("specific message content")
    error = MultiJson::AdapterError.build(original)

    # The message should contain the original exception's message
    assert_includes error.message, "specific message content"
  end

  def test_adapter_error_build_sets_cause_backtrace
    original = LoadError.new("error")
    original.set_backtrace(%w[frame1 frame2])
    error = MultiJson::AdapterError.build(original)

    assert_equal %w[frame1 frame2], error.backtrace
  end

  def test_parse_error_without_cause
    error = MultiJson::ParseError.new("test message", data: "{invalid}")

    assert_equal "test message", error.message
    assert_equal "{invalid}", error.data
    assert_nil error.backtrace
  end

  def test_parse_error_with_cause
    cause = StandardError.new("original")
    cause.set_backtrace(%w[line1 line2])
    error = MultiJson::ParseError.new("test message", data: "{bad}", cause: cause)

    assert_equal "test message", error.message
    assert_equal "{bad}", error.data
    assert_equal %w[line1 line2], error.backtrace
  end

  def test_parse_error_build_creates_error_with_original_message
    original = StandardError.new("unexpected token at position 5")
    error = MultiJson::ParseError.build(original, "{invalid json}")

    assert_instance_of MultiJson::ParseError, error
    assert_equal "unexpected token at position 5", error.message
    assert_equal "{invalid json}", error.data
  end

  def test_parse_error_build_sets_cause_backtrace
    original = StandardError.new("parse failed")
    original.set_backtrace(%w[parse_frame1 parse_frame2])
    error = MultiJson::ParseError.build(original, "bad data")

    assert_equal %w[parse_frame1 parse_frame2], error.backtrace
  end

  def test_decode_error_is_alias_for_parse_error
    assert_equal MultiJson::ParseError, MultiJson::DecodeError
  end

  def test_load_error_is_alias_for_parse_error
    assert_equal MultiJson::ParseError, MultiJson::LoadError
  end
end
