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
    #
    # @note The parent class is frozen at file load time. If a library
    #   loads ``multi_json/adapters/fast_jsonparser`` before ``oj`` is
    #   required, the dump side locks in to whichever adapter was
    #   available **at that moment** (e.g. ``json_gem``), not whichever
    #   is fastest later in the process. Require ``oj`` first (or let
    #   MultiJson's auto-detection do it) if you want Oj-backed dumping.
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
