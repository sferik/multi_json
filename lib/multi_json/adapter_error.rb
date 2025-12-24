module MultiJson
  # Raised when an adapter cannot be loaded or is not recognized.
  class AdapterError < ArgumentError
    def initialize(message = nil, cause: nil)
      super(message)
      set_backtrace(cause.backtrace) if cause
    end

    def self.build(original_exception)
      new(
        "Did not recognize your adapter specification (#{original_exception.message}).",
        cause: original_exception
      )
    end
  end
end
