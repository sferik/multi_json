# frozen_string_literal: true

require "yajl"
require_relative "../adapter"

module MultiJSON
  module Adapters
    # Use the Yajl-Ruby library to generate/parse.
    class Yajl < Adapter
      # Exception raised when JSON parsing fails
      ParseError = ::Yajl::ParseError

      class << self
        private

        # Parse a JSON string into a Ruby object
        #
        # @api private
        # @param string [String] JSON string to parse
        # @param options [Hash] parsing options
        # @return [Object] parsed Ruby object
        def _parse(string, options)
          ::Yajl::Parser.new(options).parse(string)
        end

        # Serialize a Ruby object to JSON
        #
        # @api private
        # @param object [Object] object to serialize
        # @param options [Hash] serialization options
        # @return [String] JSON string
        def _generate(object, options)
          ::Yajl::Encoder.encode(object, options)
        end
      end
    end
  end
end
