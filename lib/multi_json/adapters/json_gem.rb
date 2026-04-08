require_relative "../adapter"
require "json"

module MultiJson
  module Adapters
    # Use the JSON gem to dump/load.
    class JsonGem < Adapter
      # Exception raised when JSON parsing fails
      ParseError = ::JSON::ParserError

      defaults :load, create_additions: false, quirks_mode: true

      PRETTY_STATE_PROTOTYPE = {
        indent: "  ",
        space: " ",
        object_nl: "\n",
        array_nl: "\n"
      }.freeze
      private_constant :PRETTY_STATE_PROTOTYPE

      # Parse a JSON string into a Ruby object
      #
      # @api private
      # @param string [String] JSON string to parse
      # @param options [Hash] parsing options
      # @return [Object] parsed Ruby object
      # @raise [::JSON::ParserError] when input contains invalid bytes that
      #   cannot be transcoded to UTF-8
      #
      # @example Parse JSON string
      #   adapter.load('{"key":"value"}') #=> {"key" => "value"}
      def load(string, options = {})
        if string.encoding != Encoding::UTF_8
          begin
            string = string.encode(Encoding::UTF_8)
          rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
            raise ::JSON::ParserError, e.message
          end
        end

        ::JSON.parse(string, translate_load_options(options))
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
        opts = options.except(:adapter)
        json_object = object.respond_to?(:as_json) ? object.as_json : object
        return ::JSON.dump(json_object) if opts.empty?

        if opts.delete(:pretty)
          opts = PRETTY_STATE_PROTOTYPE.merge(opts)
          return ::JSON.pretty_generate(json_object, opts)
        end

        ::JSON.generate(json_object, opts)
      end

      private

      # Translate ``:symbolize_keys`` into JSON gem's ``:symbolize_names``
      #
      # Returns a new hash without mutating the input. ``options`` is the
      # cached hash returned from {Adapter.merged_load_options}, so in-place
      # edits would pollute the cache and corrupt subsequent calls.
      #
      # @api private
      # @param options [Hash] merged load options
      # @return [Hash] options with ``:symbolize_keys`` translated
      def translate_load_options(options)
        return options unless options[:symbolize_keys]

        options.except(:symbolize_keys).merge(symbolize_names: true)
      end
    end
  end
end
