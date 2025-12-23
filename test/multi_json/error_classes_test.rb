require_relative "../test_helper"

class ParseErrorTest < Minitest::Test
  cover "MultiJson::ParseError*"

  def test_initialize_with_no_arguments
    error = MultiJson::ParseError.new

    # Ruby returns class name when no message given to super(nil)
    assert_equal "MultiJson::ParseError", error.message
    assert_nil error.data
  end

  def test_initialize_with_message
    error = MultiJson::ParseError.new("test message")

    assert_equal "test message", error.message
  end

  def test_initialize_with_data
    error = MultiJson::ParseError.new("msg", data: "the data")

    assert_equal "the data", error.data
  end

  def test_initialize_with_cause
    cause = begin
      raise StandardError, "original"
    rescue => e
      e
    end
    error = MultiJson::ParseError.new("msg", cause: cause)

    assert_equal cause.backtrace, error.backtrace
  end

  def test_initialize_without_cause_has_nil_backtrace
    error = MultiJson::ParseError.new("msg")

    assert_nil error.backtrace
  end

  def test_data_reader
    error = MultiJson::ParseError.new(data: "custom_data")

    assert_equal "custom_data", error.data
  end

  def test_build_creates_error_with_message_string
    cause = begin
      raise StandardError, "original error"
    rescue => e
      e
    end

    error = MultiJson::ParseError.build(cause, "data")

    assert_kind_of String, error.message
    assert_equal "original error", error.message
    refute_kind_of StandardError, error.message
  end

  def test_build_extracts_message_from_exception
    cause = StandardError.new("extracted message")

    error = MultiJson::ParseError.build(cause, "data")

    assert_equal "extracted message", error.message
  end

  def test_build_sets_data
    cause = StandardError.new("error")

    error = MultiJson::ParseError.build(cause, "test_data")

    assert_equal "test_data", error.data
  end

  def test_build_sets_cause_backtrace
    cause = begin
      raise StandardError, "with trace"
    rescue => e
      e
    end

    error = MultiJson::ParseError.build(cause, "data")

    assert_equal cause.backtrace, error.backtrace
  end

  def test_build_uses_message_method_not_exception_itself
    # This test ensures we call .message on the exception, not pass the exception itself
    cause = StandardError.new("the message")

    error = MultiJson::ParseError.build(cause, "data")

    # The message should be a string, not an exception object
    assert_instance_of String, error.message
    refute_instance_of StandardError, error.message
    assert_equal "the message", error.message
  end

  def test_build_message_is_string_from_exception_message
    cause = ArgumentError.new("argument error message")

    error = MultiJson::ParseError.build(cause, "input")

    assert_equal "argument error message", error.message
    assert_kind_of String, error.message
  end

  def test_build_message_is_not_exception_object
    # Kill mutation: new(original_exception.message, ...) -> new(original_exception, ...)
    cause = StandardError.new("the error message")

    error = MultiJson::ParseError.build(cause, "data")

    # When passed correctly, message should be "the error message"
    # If passed incorrectly (the exception itself), message would be exception.to_s which is also "the error message"
    # But inspect would differ, so let's check that message is really a String not an Exception
    assert_instance_of String, error.message
    refute_kind_of Exception, error.message
  end

  def test_build_calls_message_on_exception
    # Kill mutation: original_exception.message -> original_exception
    cause = build_custom_exception

    error = MultiJson::ParseError.build(cause, "data")

    # Should use .message result, not the exception object
    assert_equal "custom message from method", error.message
    refute_equal "custom_exception_to_s", error.message
  end

  private

  def build_custom_exception
    # Create an exception where the message method returns something different than the exception itself
    custom_exception = Class.new(StandardError) do
      def message = "custom message from method"
      def to_s = "custom_exception_to_s"
    end
    custom_exception.new
  end
end

class AdapterErrorTest < Minitest::Test
  cover "MultiJson::AdapterError*"

  def test_initialize_with_no_arguments
    error = MultiJson::AdapterError.new

    # Ruby returns class name when no message given to super(nil)
    assert_equal "MultiJson::AdapterError", error.message
  end

  def test_initialize_with_message
    error = MultiJson::AdapterError.new("test message")

    assert_equal "test message", error.message
  end

  def test_initialize_with_cause
    cause = begin
      raise StandardError, "original"
    rescue => e
      e
    end
    error = MultiJson::AdapterError.new("msg", cause: cause)

    assert_equal cause.backtrace, error.backtrace
  end

  def test_initialize_without_cause_has_nil_backtrace
    error = MultiJson::AdapterError.new("msg")

    assert_nil error.backtrace
  end

  def test_build_creates_error_with_formatted_message
    cause = StandardError.new("load error")

    error = MultiJson::AdapterError.build(cause)

    assert_includes error.message, "Did not recognize your adapter specification"
    assert_includes error.message, "load error"
  end

  def test_build_extracts_message_from_exception
    cause = StandardError.new("bad adapter")

    error = MultiJson::AdapterError.build(cause)

    assert_includes error.message, "bad adapter"
    assert_kind_of String, error.message
  end

  def test_build_sets_cause_backtrace
    cause = begin
      raise StandardError, "with trace"
    rescue => e
      e
    end

    error = MultiJson::AdapterError.build(cause)

    assert_equal cause.backtrace, error.backtrace
  end

  def test_build_uses_message_method_not_exception_itself
    # Kill mutation: original_exception.message -> original_exception
    cause = StandardError.new("extracted message")

    error = MultiJson::AdapterError.build(cause)

    # The message should include the string "extracted message", not the exception's inspect
    assert_includes error.message, "extracted message"
    refute_includes error.message, "#<StandardError"
  end

  def test_build_calls_message_on_exception
    # Kill mutation: original_exception.message -> original_exception
    custom_exception = Class.new(StandardError) do
      def message = "the message"
      def to_s = "to_s_output"
      def inspect = "#<CustomException>"
    end

    cause = custom_exception.new

    error = MultiJson::AdapterError.build(cause)

    assert_includes error.message, "the message"
    refute_includes error.message, "to_s_output"
    refute_includes error.message, "#<CustomException>"
  end

  def test_build_message_contains_exception_message_string
    # Kill mutation: original_exception.message -> original_exception
    cause = StandardError.new("specific error text")

    error = MultiJson::AdapterError.build(cause)

    # Should interpolate the message string, not the exception object
    assert_includes error.message, "(specific error text)"
    refute_includes error.message, "#<StandardError"
  end
end
