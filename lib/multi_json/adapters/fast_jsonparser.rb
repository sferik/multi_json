require "fast_jsonparser"
require "oj"
require_relative "../adapter"

module MultiJson
  module Adapters
    # Use the fast_jsonparser library for loading and Oj for dumping.
    class FastJsonparser < Adapter
      defaults :load, symbolize_keys: false
      defaults :dump, mode: :compat, time_format: :ruby, use_to_json: true

      ParseError = ::FastJsonparser::Error

      def load(string, options = {})
        ::FastJsonparser.parse(string, symbolize_keys: options[:symbolize_keys])
      end

      OJ_VERSION = ::Oj::VERSION
      OJ_V2 = OJ_VERSION.start_with?("2.")
      OJ_V3 = OJ_VERSION.start_with?("3.")
      private_constant :OJ_VERSION, :OJ_V2, :OJ_V3

      if OJ_V3
        PRETTY_STATE_PROTOTYPE = {
          indent: "  ",
          space: " ",
          space_before: "",
          object_nl: "\n",
          array_nl: "\n",
          ascii_only: false
        }.freeze
        private_constant :PRETTY_STATE_PROTOTYPE
      end

      def dump(object, options = {})
        if OJ_V2
          options[:indent] = 2 if options[:pretty]
          options[:indent] = options[:indent].to_i if options[:indent]
        elsif OJ_V3
          options.merge!(PRETTY_STATE_PROTOTYPE.dup) if options.delete(:pretty)
        else
          raise "Unsupported Oj version: #{::Oj::VERSION}"
        end

        ::Oj.dump(object, options)
      end
    end
  end
end
