# frozen_string_literal: true

require_relative "../test_helper"

class AdapterErrorTest < Minitest::Test
  cover "MultiJSON::AdapterError*"

  def test_initialize_with_no_arguments
    error = MultiJSON::AdapterError.new

    # Ruby returns class name when no message given to super(nil)
    assert_equal "MultiJSON::AdapterError", error.message
  end

  def test_initialize_with_message
    error = MultiJSON::AdapterError.new("test message")

    assert_equal "test message", error.message
  end

  def test_initialize_with_cause
    cause = begin
      raise StandardError, "original"
    rescue => e
      e
    end
    error = MultiJSON::AdapterError.new("msg", cause: cause)

    assert_equal cause.backtrace, error.backtrace
  end

  def test_initialize_without_cause_has_nil_backtrace
    error = MultiJSON::AdapterError.new("msg")

    assert_nil error.backtrace
  end

  def test_build_creates_error_with_formatted_message
    cause = StandardError.new("load error")

    error = MultiJSON::AdapterError.build(cause)

    assert_includes error.message, "Did not recognize your adapter specification"
    assert_includes error.message, "load error"
  end

  def test_build_extracts_message_from_exception
    cause = StandardError.new("bad adapter")

    error = MultiJSON::AdapterError.build(cause)

    assert_includes error.message, "bad adapter"
    assert_kind_of String, error.message
  end

  def test_build_sets_cause_backtrace
    cause = begin
      raise StandardError, "with trace"
    rescue => e
      e
    end

    error = MultiJSON::AdapterError.build(cause)

    assert_equal cause.backtrace, error.backtrace
  end

  def test_build_uses_message_method_not_exception_itself
    cause = StandardError.new("extracted message")

    error = MultiJSON::AdapterError.build(cause)

    # The message should include the string "extracted message", not the exception's inspect
    assert_includes error.message, "extracted message"
    refute_includes error.message, "#<StandardError"
  end

  def test_build_calls_message_on_exception
    custom_exception = Class.new(StandardError) do
      def message = "the message"
      def to_s = "to_s_output"
      def inspect = "#<CustomException>"
    end

    cause = custom_exception.new

    error = MultiJSON::AdapterError.build(cause)

    assert_includes error.message, "the message"
    refute_includes error.message, "to_s_output"
    refute_includes error.message, "#<CustomException>"
  end

  def test_build_message_contains_exception_message_string
    cause = StandardError.new("specific error text")

    error = MultiJSON::AdapterError.build(cause)

    # Should interpolate the message string, not the exception object
    assert_includes error.message, "specific error text"
    refute_includes error.message, "#<StandardError"
  end

  def test_build_includes_exception_class_name
    cause = LoadError.new("cannot load such file -- foo")

    error = MultiJSON::AdapterError.build(cause)

    assert_includes error.message, "LoadError"
    assert_includes error.message, "cannot load such file -- foo"
  end
end
