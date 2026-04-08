require "fast_jsonparser"
require_relative "../adapter"
require_relative "../adapter_selector"

module MultiJson
  module Adapters
    # Use the FastJsonparser library to load, and the fastest other
    # available adapter to dump.
    #
    # FastJsonparser only implements parsing, so the ``dump`` side of
    # the adapter is delegated to whichever adapter MultiJson would
    # pick if FastJsonparser weren't installed (oj → yajl → jr_jackson
    # → json_gem → gson). The delegate is resolved lazily at the first
    # ``dump`` call, not at file load time, so load order doesn't lock
    # in the wrong delegate. Require any preferred dump backend before
    # the first ``dump`` call (typical applications already have ``oj``
    # loaded by then).
    class FastJsonparser < Adapter
      defaults :load, symbolize_keys: false

      # Exception raised when JSON parsing fails
      ParseError = ::FastJsonparser::ParseError

      # Mutex guarding the lazy ``@dump_delegate`` initializer.
      DUMP_DELEGATE_MUTEX = Mutex.new
      private_constant :DUMP_DELEGATE_MUTEX

      class << self
        # Serialize a Ruby object to JSON via the lazy delegate
        #
        # @api private
        # @param object [Object] object to serialize
        # @param options [Hash] serialization options
        # @return [String] JSON string
        # @example
        #   adapter.dump({key: "value"}) #=> '{"key":"value"}'
        def dump(object, options = {})
          dump_delegate.dump(object, options)
        end

        private

        # Resolve the dump delegate, caching it across calls
        #
        # @api private
        # @return [Class] delegate adapter class
        def dump_delegate
          DUMP_DELEGATE_MUTEX.synchronize do
            @dump_delegate ||= MultiJson::AdapterSelector.default_adapter_excluding(:fast_jsonparser)
          end
        end
      end

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
