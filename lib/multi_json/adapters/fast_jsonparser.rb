# frozen_string_literal: true

require "fast_jsonparser"
require_relative "../adapter"
require_relative "../adapter_selector"

module MultiJSON
  module Adapters
    # Use the FastJsonparser library to parse, and the fastest other
    # available adapter to generate.
    #
    # FastJsonparser only implements parsing, so the ``generate`` side
    # of the adapter is delegated to whichever adapter MultiJSON would
    # pick if FastJsonparser weren't installed (oj → yajl → jr_jackson
    # → json_gem → gson). The delegate is resolved lazily at the first
    # ``generate`` call, not at file load time, so load order doesn't
    # lock in the wrong delegate. Require any preferred generate
    # backend before the first ``generate`` call (typical applications
    # already have ``oj`` loaded by then).
    class FastJsonparser < Adapter
      defaults :parse, symbolize_names: false

      # Exception raised when JSON parsing fails
      ParseError = ::FastJsonparser::ParseError

      class << self
        # Serialize a Ruby object via the lazy generate delegate
        #
        # Overrides {Adapter.generate} (rather than the private
        # ``_generate`` hook the base class provides for subclasses)
        # because the base class's cached option merge would populate
        # the shared {OptionsCache} with fast_jsonparser's empty
        # generate defaults, pre-empting the delegate's own defaults
        # (e.g., Oj's ``mode: :compat``) the next time any adapter
        # fetches the same cache key. Forwarding directly through the
        # delegate's own ``.generate`` lets it own the merge.
        #
        # @api private
        # @param object [Object] object to serialize
        # @param options [Hash] serialization options
        # @return [String] JSON string
        def generate(object, options = {})
          generate_delegate.generate(object, options)
        end

        private

        # Parse a JSON string into a Ruby object
        #
        # FastJsonparser.parse only accepts ``symbolize_keys`` and raises
        # on unknown keyword arguments, so the adapter explicitly forwards
        # MultiJSON's canonical ``:symbolize_names`` option as
        # FastJsonparser's native ``symbolize_keys:`` kwarg and silently
        # drops the rest. Pass other options through
        # ``MultiJSON.parse_options=`` and they'll apply to whichever
        # adapter MultiJSON selects when fast_jsonparser isn't installed.
        #
        # @api private
        # @param string [String] JSON string to parse
        # @param options [Hash] parsing options (only :symbolize_names is honored)
        # @return [Object] parsed Ruby object
        def _parse(string, options)
          ::FastJsonparser.parse(string, symbolize_keys: options[:symbolize_names])
        end

        # Resolve the generate delegate, caching it across calls
        #
        # @api private
        # @return [Class] delegate adapter class
        def generate_delegate
          MultiJSON::Concurrency.synchronize(:generate_delegate) do
            @generate_delegate ||= MultiJSON::AdapterSelector.default_adapter_excluding(:fast_jsonparser)
          end
        end
      end
    end
  end
end
