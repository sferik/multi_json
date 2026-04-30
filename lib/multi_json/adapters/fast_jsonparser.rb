# frozen_string_literal: true

require "fast_jsonparser"
require_relative "../adapter"
require_relative "../adapter_selector"

module MultiJSON
  module Adapters
    # Use the FastJsonparser library to parse, and the fastest other
    # available adapter to generate.
    #
    # FastJsonparser only implements parsing, so the ``generate`` side of
    # the adapter is delegated to whichever adapter MultiJSON would pick
    # for generate operations if FastJsonparser weren't installed. The
    # delegate is resolved lazily at the first ``generate`` call, not at
    # file load time, so load order doesn't lock in the wrong delegate.
    class FastJsonparser < Adapter
      defaults :parse, symbolize_names: false

      # Exception raised when JSON parsing fails
      ParseError = ::FastJsonparser::ParseError

      class << self
        # Serialize a Ruby object via the lazy generate delegate
        #
        # Overrides {Adapter.generate} because the base class's cached
        # option merge would otherwise populate the shared
        # {OptionsCache} with fast_jsonparser's empty generate defaults.
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
        # drops the rest.
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
            @generate_delegate ||= MultiJSON::AdapterSelector.default_adapter_excluding(
              :fast_jsonparser,
              operation: :generate
            )
          end
        end
      end
    end
  end
end
