# frozen_string_literal: true

require "gson"
require_relative "../adapter"

module MultiJSON
  module Adapters
    # Use the gson.rb library to generate/parse.
    class Gson < Adapter
      # Exception raised when JSON parsing fails
      ParseError = ::Gson::DecodeError

      # Pre-allocated zero-options decoder/encoder for the dominant call
      # path. Without an explicit ``defaults :parse`` / ``defaults :generate``
      # block on this adapter, ``MultiJSON.parse(json)`` and
      # ``MultiJSON.generate(obj)`` arrive here with the shared frozen
      # empty hash from {Adapter.strip_adapter_key}, so reusing a single
      # decoder/encoder instance avoids the per-call ``Decoder.new`` /
      # ``Encoder.new`` allocation that the previous implementation
      # incurred. Java Gson is documented thread-safe, so sharing the
      # underlying handle across threads is safe.
      DEFAULT_DECODER = ::Gson::Decoder.new({})
      DEFAULT_ENCODER = ::Gson::Encoder.new({})
      private_constant :DEFAULT_DECODER, :DEFAULT_ENCODER

      class << self
        private

        # Parse a JSON string into a Ruby object
        #
        # @api private
        # @param string [String] JSON string to parse
        # @param options [Hash] parsing options
        # @return [Object] parsed Ruby object
        def _parse(string, options)
          decoder = options.empty? ? DEFAULT_DECODER : ::Gson::Decoder.new(translate_parse_options(options))
          decoder.decode(string)
        end

        # Serialize a Ruby object to JSON
        #
        # @api private
        # @param object [Object] object to serialize
        # @param options [Hash] serialization options
        # @return [String] JSON string
        def _generate(object, options)
          encoder = options.empty? ? DEFAULT_ENCODER : ::Gson::Encoder.new(options)
          encoder.encode(object)
        end

        # Translate ``:symbolize_names`` into Gson's ``:symbolize_keys``
        #
        # Returns a new hash without mutating the input. The input is the
        # cached hash returned from {Adapter.merged_parse_options}, so
        # in-place edits would pollute the cache.
        #
        # @api private
        # @param options [Hash] merged parse options
        # @return [Hash] options with ``:symbolize_names`` translated
        def translate_parse_options(options)
          return options unless options.key?(:symbolize_names)

          options.except(:symbolize_names).merge(symbolize_keys: options[:symbolize_names])
        end
      end
    end
  end
end
