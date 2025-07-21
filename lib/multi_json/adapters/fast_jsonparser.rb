require "fast_jsonparser"
require "oj"
require_relative "../adapter"
require_relative "oj_common"

module MultiJson
  module Adapters
    # Use the FastJsonparser library to load and Oj to dump.
    class FastJsonparser < Adapter
      include OjCommon
      defaults :load, symbolize_keys: false
      defaults :dump, mode: :compat, time_format: :ruby, use_to_json: true

      ParseError = ::FastJsonparser::ParseError

      def load(string, options = {})
        ::FastJsonparser.parse(string, symbolize_keys: options[:symbolize_keys])
      end

      def dump(object, options = {})
        ::Oj.dump(object, prepare_dump_options(options))
      end
    end
  end
end
