# frozen_string_literal: true

require "jrjackson" unless defined?(JrJackson)
require_relative "../adapter"

module MultiJSON
  module Adapters
    # Use the jrjackson.rb library to dump/load.
    class JrJackson < Adapter
      # Exception raised when JSON parsing fails
      ParseError = ::JrJackson::ParseError

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
        ::JrJackson::Json.load(string, translate_load_options(options))
      end

      # Serialize a Ruby object to JSON
      #
      # Requires JrJackson >= 0.4.18, which accepts an options hash as
      # the second argument to ``Json.dump``.
      #
      # @api private
      # @param object [Object] object to serialize
      # @param options [Hash] serialization options
      # @return [String] JSON string
      #
      # @example Serialize object to JSON
      #   adapter.dump({key: "value"}) #=> '{"key":"value"}'
      def dump(object, options = {})
        ::JrJackson::Json.dump(object, options)
      end

      private

      # Translate ``:symbolize_names`` into JrJackson's ``:symbolize_keys``
      #
      # Returns a new hash without mutating the input. The input is the
      # cached hash returned from {Adapter.merged_load_options}, so
      # in-place edits would pollute the cache.
      #
      # @api private
      # @param options [Hash] merged load options
      # @return [Hash] options with ``:symbolize_names`` translated
      def translate_load_options(options)
        return options unless options.key?(:symbolize_names)

        options.except(:symbolize_names).merge(symbolize_keys: options[:symbolize_names])
      end
    end
  end
end
