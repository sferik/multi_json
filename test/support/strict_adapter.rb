# frozen_string_literal: true

# Custom adapter that verifies exact argument signatures
class StrictAdapter
  class ParseError < StandardError; end

  class << self
    attr_accessor :parse_calls, :generate_calls

    def reset_calls
      @parse_calls = []
      @generate_calls = []
    end

    def parse(string, options)
      raise ArgumentError, "string cannot be nil" if string.nil?

      @parse_calls ||= []
      @parse_calls << {string: string, options: options}

      return symbolize_keys(::JSON.parse(string)) if options[:symbolize_names]

      ::JSON.parse(string)
    rescue ::JSON::ParserError => e
      raise ParseError, e.message
    end

    def generate(object, options)
      raise ArgumentError, "object cannot be nil" if object.nil?

      @generate_calls ||= []
      @generate_calls << {object: object, options: options}
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
