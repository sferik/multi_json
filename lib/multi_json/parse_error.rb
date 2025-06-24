module MultiJson
  class ParseError < StandardError
    attr_reader :data, :cause

    def initialize(message = nil, data: nil, cause: nil)
      super(message)
      @data = data
      @cause = cause
      set_backtrace(cause.backtrace) if cause
    end

    def self.build(original_exception, data)
      new(original_exception.message, data: data, cause: original_exception)
    end
  end

  DecodeError = LoadError = ParseError # Legacy support
end
