# frozen_string_literal: true

require "gson"
require_relative "../adapter"

module MultiJson
  module Adapters
    # Use the gson.rb library to dump/load.
    class Gson < Adapter
      # Exception raised when JSON parsing fails
      ParseError = ::Gson::DecodeError

      # Pre-allocated zero-options decoder/encoder for the dominant call
      # path. Without an explicit ``defaults :load`` / ``defaults :dump``
      # block on this adapter, ``MultiJson.load(json)`` and
      # ``MultiJson.dump(obj)`` arrive here with the shared frozen empty
      # hash from {Adapter.strip_adapter_key}, so reusing a single
      # decoder/encoder instance avoids the per-call ``Decoder.new`` /
      # ``Encoder.new`` allocation that the previous implementation
      # incurred. Java Gson is documented thread-safe, so sharing the
      # underlying handle across threads is safe.
      DEFAULT_DECODER = ::Gson::Decoder.new({})
      DEFAULT_ENCODER = ::Gson::Encoder.new({})
      private_constant :DEFAULT_DECODER, :DEFAULT_ENCODER

      # Parse a JSON string into a Ruby object
      #
      # @api private
      # @param string [String] JSON string to parse
      # @param options [Hash] parsing options
      # @return [Object] parsed Ruby object
      #
      # @example Parse JSON string
      #   adapter.load('{"key":"value"}') #=> {"key" => "value"}
      def load(string, options = {})
        decoder = options.empty? ? DEFAULT_DECODER : ::Gson::Decoder.new(options)
        decoder.decode(string)
      end

      # Serialize a Ruby object to JSON
      #
      # @api private
      # @param object [Object] object to serialize
      # @param options [Hash] serialization options
      # @return [String] JSON string
      #
      # @example Serialize object to JSON
      #   adapter.dump({key: "value"}) #=> '{"key":"value"}'
      def dump(object, options = {})
        encoder = options.empty? ? DEFAULT_ENCODER : ::Gson::Encoder.new(options)
        encoder.encode(object)
      end
    end
  end
end
