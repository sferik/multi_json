# Custom adapter that verifies exact argument signatures
class StrictAdapter
  class ParseError < StandardError; end

  class << self
    attr_accessor :load_calls, :dump_calls

    def reset_calls
      @load_calls = []
      @dump_calls = []
    end

    def load(string, options)
      raise ArgumentError, "string cannot be nil" if string.nil?

      @load_calls ||= []
      @load_calls << {string: string, options: options}

      return symbolize_keys(::JSON.parse(string)) if options[:symbolize_keys]

      ::JSON.parse(string)
    rescue ::JSON::ParserError => e
      raise ParseError, e.message
    end

    def dump(object, options)
      raise ArgumentError, "object cannot be nil" if object.nil?

      @dump_calls ||= []
      @dump_calls << {object: object, options: options}
      ::JSON.generate(object)
    end

    private

    def symbolize_keys(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(k, v), h|
        h[k.to_sym] = symbolize_keys(v)
      end
    end
  end
end
