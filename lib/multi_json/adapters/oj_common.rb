module MultiJson
  module Adapters
    module OjCommon
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

      private

      def prepare_dump_options(options)
        if OJ_V2
          options[:indent] = 2 if options[:pretty]
          options[:indent] = options[:indent].to_i if options[:indent]
        elsif OJ_V3
          options.merge!(PRETTY_STATE_PROTOTYPE.dup) if options.delete(:pretty)
        else
          raise "Unsupported Oj version: #{::Oj::VERSION}"
        end

        options
      end
    end
  end
end
