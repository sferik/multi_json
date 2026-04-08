require "fast_jsonparser"
require_relative "../adapter_selector"

module MultiJson
  module Adapters
    # Use the FastJsonparser library to load, and the fastest other
    # available adapter to dump.
    #
    # FastJsonparser only implements parsing, so the ``dump`` side of the
    # adapter is delegated to whichever adapter MultiJson would pick if
    # FastJsonparser weren't installed (oj → yajl → jr_jackson →
    # json_gem → gson → ok_json). The parent class is resolved at load
    # time via {MultiJson::AdapterSelector.default_adapter_excluding},
    # so the heavy oj dependency is no longer implied.
    class FastJsonparser < MultiJson::AdapterSelector.default_adapter_excluding(:fast_jsonparser)
      defaults :load, symbolize_keys: false

      # Exception raised when JSON parsing fails
      ParseError = ::FastJsonparser::ParseError

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
        ::FastJsonparser.parse(string, symbolize_keys: options[:symbolize_keys])
      end
    end
  end
end
