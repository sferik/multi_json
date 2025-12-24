module MultiJson
  # Raised when JSON parsing fails.
  # Wraps the underlying adapter's parse error with the original input data.
  class ParseError < StandardError
    # The input string that failed to parse
    attr_reader :data

    def initialize(message = nil, data: nil, cause: nil)
      super(message)
      @data = data
      set_backtrace(cause.backtrace) if cause
    end

    def self.build(original_exception, data)
      new(original_exception.message, data: data, cause: original_exception)
    end
  end

  # Legacy aliases for backward compatibility
  DecodeError = LoadError = ParseError
end
